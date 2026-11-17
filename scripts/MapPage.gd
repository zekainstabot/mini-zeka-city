extends RefCounted

# Lightweight, data-driven neighborhood map using native Godot controls.
static func build(owner, city_state):
	var overview = owner.game.get_districts_overview()
	var districts = overview.get("districts", [])
	owner._add_label("🗺️ نقشه شهر", 24)
	owner._add_label("برای دیدن وضعیت هر محله، آن را انتخاب کن.", 15)

	var panel = PanelContainer.new()
	panel.name = "DistrictMapPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("#172b40")
	panel_style.border_color = Color("#3b607d")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(16)
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	owner.content.add_child(panel)

	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	panel.add_child(body)
	var heading = Label.new()
	heading.text = owner.PersianText.reshaper("محله‌های شهر  •  %d محله" % districts.size())
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owner._apply_font(heading, 17)
	body.add_child(heading)

	if districts.is_empty():
		var empty_label = Label.new()
		empty_label.text = owner.PersianText.reshaper("هنوز محله‌ای ایجاد نشده است. با ساخت اولین ساختمان داخل شهر، محله به‌صورت خودکار ساخته می‌شود.")
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		owner._apply_font(empty_label, 15)
		body.add_child(empty_label)
	else:
		var grid = GridContainer.new()
		grid.name = "DistrictMapGrid"
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		body.add_child(grid)
		for index in range(districts.size()):
			var district = districts[index]
			var district_id = str(district.get("id", ""))
			var selected = district_id == owner.selected_map_district_id
			var tile = Button.new()
			tile.name = "DistrictTile_" + district_id
			tile.text = owner.PersianText.reshaper("%s\n🏘️ %d ساختمان\n%s" % [str(district.get("name", "محله " + district_id)), int(district.get("building_count", 0)), "انتخاب‌شده ✓" if selected else "برای مشاهده لمس کن"])
			tile.custom_minimum_size = Vector2(0, 92)
			tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tile.alignment = HORIZONTAL_ALIGNMENT_CENTER
			tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			owner._apply_font(tile, 15)
			var fill = Color("#28513f") if index % 2 == 0 else Color("#315344")
			if selected:
				fill = Color("#365b78")
			tile.add_theme_stylebox_override("normal", owner._button_style(fill, Color("#93c5fd") if selected else Color("#86efac")))
			tile.add_theme_stylebox_override("hover", owner._button_style(fill.lightened(0.12), Color("#f8fafc")))
			tile.add_theme_stylebox_override("pressed", owner._button_style(fill.darkened(0.12), Color("#f8fafc")))
			tile.pressed.connect(Callable(owner, "select_map_district").bind(district_id))
			grid.add_child(tile)

	if owner.selected_map_district_id != "":
		var selected_district = {}
		for district in districts:
			if str(district.get("id", "")) == owner.selected_map_district_id:
				selected_district = district
				break
		if not selected_district.is_empty():
			var details = PanelContainer.new()
			details.name = "SelectedDistrictDetails"
			details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var detail_style = StyleBoxFlat.new()
			detail_style.bg_color = Color("#223b53")
			detail_style.border_color = Color("#60a5fa")
			detail_style.set_border_width_all(1)
			detail_style.set_corner_radius_all(12)
			detail_style.content_margin_left = 10
			detail_style.content_margin_right = 10
			detail_style.content_margin_top = 9
			detail_style.content_margin_bottom = 9
			details.add_theme_stylebox_override("panel", detail_style)
			body.add_child(details)
			var detail_body = VBoxContainer.new()
			detail_body.add_theme_constant_override("separation", 5)
			details.add_child(detail_body)
			var title = Label.new()
			title.text = owner.PersianText.reshaper("📍 %s" % str(selected_district.get("name", "محله")))
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			owner._apply_font(title, 18)
			detail_body.add_child(title)
			var counts = Label.new()
			counts.text = owner.PersianText.reshaper("ساختمان‌ها: %d  •  خانه‌ها: %d  •  سایر ساختمان‌ها: %d" % [int(selected_district.get("building_count", 0)), int(selected_district.get("house_count", 0)), int(selected_district.get("other_count", 0)) + int(selected_district.get("emergency_count", 0))])
			counts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			counts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			owner._apply_font(counts, 14)
			detail_body.add_child(counts)
			var names = selected_district.get("building_names", [])
			var names_label = Label.new()
			names_label.text = owner.PersianText.reshaper("ساختمان‌های محله: " + ("، ".join(names) if not names.is_empty() else "هنوز ساختمانی ثبت نشده است."))
			names_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			names_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			owner._apply_font(names_label, 14)
			detail_body.add_child(names_label)

	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	body.add_child(actions)
	var buildings_button = Button.new()
	buildings_button.text = owner.PersianText.reshaper("مدیریت ساختمان‌ها")
	buildings_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buildings_button.custom_minimum_size.y = 52
	owner._apply_font(buildings_button, 15)
	owner._style_button(buildings_button, false)
	buildings_button.pressed.connect(Callable(owner, "show_page").bind("buildings"))
	actions.add_child(buildings_button)
	var home_button = Button.new()
	home_button.text = owner.PersianText.reshaper("بازگشت به شهر من")
	home_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_button.custom_minimum_size.y = 52
	owner._apply_font(home_button, 15)
	owner._style_button(home_button, false)
	home_button.pressed.connect(Callable(owner, "show_page").bind("home"))
	actions.add_child(home_button)
