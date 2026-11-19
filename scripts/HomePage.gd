extends RefCounted

# Builds the city overview, status cards, and home actions.
static func build(owner, s):
	var game = owner.game
	owner._add_label("وضعیت کلی شهر", 22)
	owner._show_welcome_mission_hint()
	_add_city_overview_panel(owner, s)
	_add_active_construction_panel(owner)
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

	owner._add_label("جمعیت: %d نفر  |  شاغل: %d  |  بیکار: %d" % [s.population,game.get_employed_count(),game.get_unemployed_count()], 19)
	var login_calendar_button = owner._add_button("📅 تقویم جایزه‌های ورود", owner, "_open_daily_reward_calendar")
	owner._style_button(login_calendar_button, false)
	var municipal_economy = s.get("last_economy", {})
	var municipal_daily_income = int(municipal_economy.get("tax_income",0)) + int(municipal_economy.get("consumer_tax_income",0)) + int(municipal_economy.get("station_income",0)) + int(municipal_economy.get("road_income",0))
	var municipal_daily_total = int(municipal_economy.get("accepted_income",0))
	owner._add_label("درآمد روزانه شهرداری: %d سکه" % municipal_daily_total, 18)
	owner._add_label("اعتبار شهر: %d  |  رضایت: %d/۱۰۰" % [s.reputation,int(s.get("satisfaction",50))], 18)

	owner._add_home_services_panel(s)

	var buildings_toggle = owner._add_button(("▼ " if owner.home_buildings_expanded else "▶ ") + "ساختمان‌های ساخته‌شده", owner, "toggle_home_buildings")
	owner._style_button(buildings_toggle, false)
	if owner.home_buildings_expanded:
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

	var demolish_toggle = owner._add_button(("▼ " if owner.demolish_panel_expanded else "▶ ") + "مدیریت تخریب ساختمان‌ها", owner, "toggle_demolish_panel")
	owner._style_button(demolish_toggle, false)
	if owner.demolish_panel_expanded:
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

	var economy_toggle = owner._add_button(("▼ " if owner.home_economy_expanded else "▶ ") + "منابع و گزارش مالی", owner, "toggle_home_economy")
	owner._style_button(economy_toggle, false)
	if owner.home_economy_expanded:
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
	_add_overview_metric(owner, grid, "👥 جمعیت", "%d نفر" % int(city_state.get("population", 0)), Color("#bfdbfe"))
	_add_overview_metric(owner, grid, "🧑‍🏭 نیروی کار", "%d شاغل  •  %d بیکار" % [employed, unemployed], Color("#a7f3d0"))
	_add_overview_metric(owner, grid, "🏅 سطح و اعتبار", "سطح %d  •  اعتبار %d" % [int(city_state.get("level", 1)), int(city_state.get("reputation", 0))], Color("#fde68a"))
	_add_overview_metric(owner, grid, "😊 رضایت شهروندان", "%d از ۱۰۰" % satisfaction, Color("#c4b5fd"))
	_add_overview_metric(owner, grid, "💰 موجودی خزانه", "%s سکه" % str(int(city_state.get("money", 0))), Color("#fde68a"))
	_add_overview_metric(owner, grid, "🪙 Zeka Coin", "%s ZC" % str(owner.game.get_zeka_coins()), Color("#fcd34d"))

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

static func _add_active_construction_panel(owner):
	var projects = owner.game.get_construction_status()
	if projects.is_empty():
		return
	var panel = PanelContainer.new()
	panel.name = "HomeConstructionPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#302b20")
	style.border_color = Color("#a16207")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	panel.add_theme_stylebox_override("panel", style)
	owner.content.add_child(panel)
	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 7)
	panel.add_child(body)
	var heading = Label.new()
	heading.text = owner.PersianText.reshaper("🏗️ پروژه‌های در حال ساخت  •  %d از ۲" % projects.size())
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner._apply_font(heading, 18)
	heading.add_theme_color_override("font_color", Color("#fde68a"))
	body.add_child(heading)
	for project in projects:
		var remaining = max(0, int(project.get("remaining", 0)))
		var time_text = "%02d:%02d" % [int(remaining / 60), remaining % 60]
		var detail = Label.new()
		detail.text = owner.PersianText.reshaper("🔨 %s\n📍 %s  •  زمان باقی‌مانده: %s" % [str(project.get("name", "ساختمان")), str(project.get("district_name", "منطقه شهر")), time_text])
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		owner._apply_font(detail, 15)
		detail.add_theme_color_override("font_color", Color("#f8fafc"))
		body.add_child(detail)
	var manage = Button.new()
	manage.text = owner.PersianText.reshaper("مدیریت پروژه‌های ساخت‌وساز")
	manage.custom_minimum_size = Vector2(0, 52)
	manage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	manage.alignment = HORIZONTAL_ALIGNMENT_CENTER
	manage.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(manage, 16)
	owner._style_button(manage, false)
	manage.pressed.connect(Callable(owner, "show_page").bind("buildings"))
	body.add_child(manage)

