extends RefCounted

# Builds the city overview, status cards, and home actions.
static func build(owner, s):
	var game = owner.game
	owner._add_label("وضعیت کلی شهر", 22)
	owner._show_welcome_mission_hint()
	_add_city_overview_panel(owner, s)
	var weekly_city_event = game.get_weekly_city_event()
	owner._add_label("🌟 رویداد این هفته: %s" % str(weekly_city_event.get("title","")),17)
	owner._add_label("%s | اثر: %s" % [str(weekly_city_event.get("description","")),str(weekly_city_event.get("effect",""))],14)

	var pending_decision = game.get_pending_city_decision()
	if not pending_decision.is_empty():
		owner._add_label("⚖️ تصمیم مهم شهروندان",20)
		owner._add_label(str(pending_decision.get("title","تصمیم شهر")),18)
		owner._add_label(str(pending_decision.get("description","")),15)
		for decision_option in pending_decision.get("options", []):
			owner._add_button(str(decision_option.get("label","انتخاب")),owner,"resolve_city_decision",[str(decision_option.get("id",""))])
	var recent_city_events = s.get("city_event_history",[])
	if not recent_city_events.is_empty():
		var recent_event = recent_city_events[recent_city_events.size()-1]
		owner._add_label("🎲 آخرین اتفاق شهر | روز %d: %s" % [int(recent_event.get("day",s.day)),str(recent_event.get("title","رویداد"))],16)


	# Section details are rendered below the overview action cards.
	owner._add_home_services_panel(s)
	if owner.home_buildings_expanded:
		var buildings_heading = owner._add_label("🏗️ ساختمان‌های ساخته‌شده", 19)
		buildings_heading.name = "HomeBuildingsSectionStart"
		var home_categories = ["خانه‌ها","کشاورزی","معادن","کارخانه‌ها","کسب‌وکارها","خدمات شهری","تفریح و فرهنگ","انبارها"]
		var any_home_building = false
		for home_category in home_categories:
			var category_rows = []
			for home_id in game.get_building_definitions().keys():
				var home_data = game.get_building_definitions()[home_id]
				if str(home_data.get("category","")) == home_category:
					var home_count = game.get_building_count(home_id)
					if home_count > 0:
						category_rows.append({"id":home_id,"name":str(home_data.name),"count":home_count})
			if not category_rows.is_empty():
				any_home_building = true
				owner._add_label("【"+home_category+"】", 17)
				for home_row in category_rows:
					owner._add_label("%s  |  تعداد: %d" % [home_row.name,home_row.count], 16)
		if not any_home_building:
			owner._add_label("هنوز ساختمانی در شهر ساخته نشده است.", 16)

	if owner.demolish_panel_expanded:
		var demolish_heading = owner._add_label("🧱 مدیریت تخریب ساختمان‌ها", 19)
		demolish_heading.name = "HomeDemolishSectionStart"
		owner._add_label("ساختمان موردنظر را انتخاب کن:", 16)
		for home_id in game.get_building_definitions().keys():
			var home_count = game.get_building_count(home_id)
			if home_count <= 0:
				continue
			var home_data = game.get_building_definitions()[home_id]
			var home_button = owner._add_button("%s  |  تعداد: %d" % [str(home_data.name),home_count], owner, "select_home_building", [home_id])
			owner._style_button(home_button, false)
			if owner.selected_home_building_id == str(home_id):
				home_button.add_theme_color_override("font_color", Color("#fde68a"))
		if owner.selected_home_building_id != "" and game.get_building_count(owner.selected_home_building_id) > 0:
			var selected_definition = game.get_building_definitions()[owner.selected_home_building_id]
			var selected_count = game.get_building_count(owner.selected_home_building_id)
			owner._add_label("انتخاب‌شده: %s  |  موجود: %d" % [selected_definition.name,selected_count], 17)
			owner._add_label("تعداد برای تخریب: %d" % owner.selected_demolish_quantity, 16)
			var quantity_row = HBoxContainer.new()
			quantity_row.add_theme_constant_override("separation", 8)
			owner.content.add_child(quantity_row)
			var less_button = Button.new()
			less_button.text = "−"
			less_button.custom_minimum_size = Vector2(70,58)
			owner._apply_font(less_button,24)
			owner._style_button(less_button,false)
			less_button.connect("pressed", Callable(owner, "adjust_demolish_quantity").bind(-1))
			quantity_row.add_child(less_button)
			var more_button = Button.new()
			more_button.text = "+"
			more_button.custom_minimum_size = Vector2(70,58)
			owner._apply_font(more_button,24)
			owner._style_button(more_button,false)
			more_button.connect("pressed", Callable(owner, "adjust_demolish_quantity").bind(1))
			quantity_row.add_child(more_button)
			var demolish_button = owner._add_button("تخریب %d عدد از %s" % [owner.selected_demolish_quantity,selected_definition.name],owner,"demolish_selected_buildings")
			owner._style_button(demolish_button, false)
			if owner.selected_home_building_id == "small_house" and selected_count <= 1:
				demolish_button.disabled = true
		else:
			owner._add_label("برای تخریب، ابتدا یک ساختمان را انتخاب کن.", 15)

	if owner.home_economy_expanded:
		var economy_heading = owner._add_label("📊 منابع و گزارش مالی", 19)
		economy_heading.name = "HomeEconomySectionStart"
		owner._add_label("منابع: " + owner._resource_summary(), 16)
		owner._add_label("ذخیره غذای شهر: %d واحد" % int(s.resources.get("food",0)), 16)
		var home_economy = s.get("last_economy", {})
		owner._add_label("آخرین تراز روزانه: %d سکه" % int(home_economy.get("net_cashflow",0)), 17)
		owner._add_label("درآمد ایستگاه‌ها و پایانه‌ها: %d سکه" % int(home_economy.get("station_income",0)), 16)
		owner._add_label("عوارض جاده‌ای: %d سکه" % int(home_economy.get("road_income",0)), 16)
	var brand_handle = owner._add_label("zekamediafa", 13)
	brand_handle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand_handle.add_theme_color_override("font_color", Color("#94a3b8"))

static func _add_city_overview_panel(owner, city_state):
	var panel = PanelContainer.new()
	panel.name = "HomeOverviewPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#172b40")
	style.border_color = Color("#3b607d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	owner.content.add_child(panel)

	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	panel.add_child(body)
	var heading = Label.new()
	heading.text = owner.PersianText.reshaper("نمای کلی شهر")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner._apply_font(heading, 18)
	heading.add_theme_color_override("font_color", Color("#f8fafc"))
	body.add_child(heading)

	var grid = GridContainer.new()
	grid.name = "CityOverviewGrid"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	var employed = owner.game.get_employed_count()
	var unemployed = owner.game.get_unemployed_count()
	var satisfaction = int(city_state.get("satisfaction", 50))
	var municipal_daily_total = int(city_state.get("last_economy", {}).get("accepted_income", 0))
	_add_overview_metric(owner, grid, "👥 جمعیت", "%d نفر" % int(city_state.get("population", 0)), Color("#bfdbfe"))
	_add_overview_metric(owner, grid, "🧑‍🏭 نیروی کار", "%d شاغل  •  %d بیکار" % [employed, unemployed], Color("#a7f3d0"))
	_add_overview_metric(owner, grid, "😊 رضایت شهروندان", "%d از ۱۰۰" % satisfaction, Color("#c4b5fd"))
	_add_overview_metric(owner, grid, "🏛️ اعتبار شهرداری", "%d از ۱۰۰" % int(city_state.get("reputation", 50)), Color("#fcd34d"))
	_add_overview_metric(owner, grid, "💰 درآمد روزانه شهرداری", "%d سکه" % municipal_daily_total, Color("#86efac"))
	_add_overview_action(owner, grid, "📋 گزارش‌ها و مشکلات شهر", "مشاهده گزارش‌ها و رسیدگی به مشکلات", "report", Color("#93c5fd"))
	_add_overview_action(owner, grid, "🏛️ شهرداری و خدمات شهری", "مدیریت خدمات و امور شهرداری", "municipality", Color("#fcd34d"))
	_add_overview_action(owner, grid, "🏢 اقتصاد خصوصی", "کسب‌وکارها و مشارکت شهروندان", "private_economy", Color("#86efac"))
	_add_overview_action(owner, grid, "🏙️ خدمات شهری", "وضعیت خدمات و زیرساخت‌های شهر", "toggle_home_city_details", Color("#fcd34d"))
	_add_overview_action(owner, grid, "🏗️ ساختمان‌های ساخته‌شده", "فهرست ساختمان‌های فعال شهر", "toggle_home_buildings", Color("#a5b4fc"))
	_add_overview_action(owner, grid, "🧱 مدیریت تخریب ساختمان‌ها", "انتخاب و تخریب ساختمان‌های شهر", "toggle_demolish_panel", Color("#fca5a5"))
	_add_overview_action(owner, grid, "📊 منابع و گزارش مالی", "منابع، ذخایر و تراز مالی شهر", "toggle_home_economy", Color("#86efac"))

static func _add_overview_action(owner, parent, title_text, description_text, target_page, accent_color):
	var button = Button.new()
	button.name = "HomeAction_" + str(target_page)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 82)
	button.text = owner.PersianText.reshaper(str(title_text) + "\n" + str(description_text))
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(button, 14)
	owner._style_button(button, false)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#223b53")
	style.border_color = Color("#3b526a")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(style_name, style)
	button.add_theme_color_override("font_color", Color("#f8fafc"))
	button.add_theme_color_override("font_hover_color", accent_color)
	button.add_theme_color_override("font_pressed_color", accent_color)
	button.pressed.connect(Callable(owner, "show_page").bind(str(target_page)))
	parent.add_child(button)
	return button

static func _add_overview_metric(owner, parent, caption, value, value_color):
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#223b53")
	style.border_color = Color("#3b526a")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 3)
	card.add_child(stack)
	var title = Label.new()
	title.text = owner.PersianText.reshaper(caption)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(title, 13)
	title.add_theme_color_override("font_color", Color("#cbd5e1"))
	stack.add_child(title)
	var amount = Label.new()
	amount.text = owner.PersianText.reshaper(value)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(amount, 15)
	amount.add_theme_color_override("font_color", value_color)
	stack.add_child(amount)
