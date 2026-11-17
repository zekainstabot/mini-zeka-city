extends RefCounted

# A lightweight, responsive top-down city map built entirely from native controls.
# Districts are arranged as city blocks with visible streets between them.
static func build(owner, city_state):
	var overview = owner.game.get_districts_overview()
	var districts = overview.get("districts", [])

	owner._add_label("🗺️ نقشه شهر", 24)
	owner._add_label("محله‌ها، خیابان‌ها و بافت شهر را از نمای بالا ببین.", 14)

	var map_panel = PanelContainer.new()
	map_panel.name = "CityMapCanvas"
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var map_style = StyleBoxFlat.new()
	map_style.bg_color = Color("#142b35")
	map_style.border_color = Color("#31515a")
	map_style.set_border_width_all(1)
	map_style.set_corner_radius_all(16)
	map_style.content_margin_left = 9
	map_style.content_margin_right = 9
	map_style.content_margin_top = 10
	map_style.content_margin_bottom = 10
	map_panel.add_theme_stylebox_override("panel", map_style)
	owner.content.add_child(map_panel)

	var map_body = VBoxContainer.new()
	map_body.add_theme_constant_override("separation", 0)
	map_panel.add_child(map_body)

	_add_map_header(owner, map_body, districts.size())

	if districts.is_empty():
		var empty = Label.new()
		empty.text = owner.PersianText.reshaper("هنوز محله‌ای در شهر شکل نگرفته است. با ساخت اولین ساختمان، نقشه شهر به‌تدریج ساخته می‌شود.")
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size.y = 110
		owner._apply_font(empty, 15)
		map_body.add_child(empty)
	else:
		var index = 0
		while index < districts.size():
			var street_row = HBoxContainer.new()
			street_row.add_theme_constant_override("separation", 0)
			street_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			map_body.add_child(street_row)

			var first = districts[index]
			street_row.add_child(_make_district_block(owner, first, index, index + 1 < districts.size()))
			index += 1

			var center_road = _make_vertical_road()
			street_row.add_child(center_road)

			if index < districts.size():
				var second = districts[index]
				street_row.add_child(_make_district_block(owner, second, index, false))
				index += 1
			else:
				street_row.add_child(_make_empty_block(owner))

			if index < districts.size():
				map_body.add_child(_make_horizontal_road())

		_add_map_legend(owner, map_body)

	if owner.selected_map_district_id != "":
		var selected_district = {}
		for district in districts:
			if str(district.get("id", "")) == owner.selected_map_district_id:
				selected_district = district
				break
		if not selected_district.is_empty():
			_add_district_details(owner, selected_district)

static func _add_map_header(owner, parent, district_count):
	var header = PanelContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#203d46")
	style.set_corner_radius_all(10)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	header.add_theme_stylebox_override("panel", style)
	parent.add_child(header)

	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	header.add_child(row)

	var status = Label.new()
	status.text = owner.PersianText.reshaper("● نقشه زنده")
	status.add_theme_color_override("font_color", Color("#86efac"))
	owner._apply_font(status, 12)
	row.add_child(status)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var count = Label.new()
	count.text = owner.PersianText.reshaper("%d محله" % district_count)
	count.add_theme_color_override("font_color", Color("#e2e8f0"))
	owner._apply_font(count, 14)
	row.add_child(count)

static func _make_district_block(owner, district, index, has_neighbor):
	var district_id = str(district.get("id", ""))
	var selected = district_id == owner.selected_map_district_id
	var panel = PanelContainer.new()
	panel.name = "DistrictTile_" + district_id
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 126)

	var accent = _district_color(index)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#254b43") if index % 2 == 0 else Color("#2b5148")
	style.border_color = Color("#facc15") if selected else accent
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(9)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 7
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	panel.add_child(stack)

	var top = HBoxContainer.new()
	top.add_theme_constant_override("separation", 4)
	stack.add_child(top)

	var marker = ColorRect.new()
	marker.color = accent
	marker.custom_minimum_size = Vector2(7, 7)
	marker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(marker)

	var title = Label.new()
	title.text = owner.PersianText.reshaper(str(district.get("name", "محله " + district_id)))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.clip_text = true
	owner._apply_font(title, 13)
	title.add_theme_color_override("font_color", Color("#f8fafc"))
	top.add_child(title)

	var building_count = int(district.get("building_count", 0))
	var houses = int(district.get("house_count", 0))
	var other = int(district.get("other_count", 0)) + int(district.get("emergency_count", 0))

	var stats = Label.new()
	stats.text = owner.PersianText.reshaper("🏘 %d ساختمان  |  🏠 %d خانه" % [building_count, houses])
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(stats, 11)
	stats.add_theme_color_override("font_color", Color("#d1fae5"))
	stack.add_child(stats)

	var mini_buildings = HBoxContainer.new()
	mini_buildings.alignment = BoxContainer.ALIGNMENT_CENTER
	mini_buildings.add_theme_constant_override("separation", 4)
	mini_buildings.custom_minimum_size.y = 27
	stack.add_child(mini_buildings)
	var icon_count = clamp(building_count, 0, 6)
	for n in range(icon_count):
		var building_mark = Panel.new()
		building_mark.custom_minimum_size = Vector2(15, 19 if n % 2 == 0 else 14)
		var mark_style = StyleBoxFlat.new()
		mark_style.bg_color = Color("#d6c7a1") if n % 3 == 0 else Color("#b8c9d0")
		mark_style.border_color = Color("#64748b")
		mark_style.set_border_width_all(1)
		mark_style.set_corner_radius_all(2)
		building_mark.add_theme_stylebox_override("panel", mark_style)
		mini_buildings.add_child(building_mark)
	if building_count == 0:
		var empty_mark = Label.new()
		empty_mark.text = "زمین خالی"
		empty_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		owner._apply_font(empty_mark, 10)
		empty_mark.add_theme_color_override("font_color", Color("#bbd4c9"))
		mini_buildings.add_child(empty_mark)

	var footer = Label.new()
	footer.text = owner.PersianText.reshaper("🏢 %d خدمات و سایر" % other)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owner._apply_font(footer, 10)
	footer.add_theme_color_override("font_color", Color("#cbd5e1"))
	stack.add_child(footer)

	var tap = Button.new()
	tap.name = "DistrictSelect_" + district_id
	tap.flat = true
	tap.focus_mode = Control.FOCUS_NONE
	tap.mouse_filter = Control.MOUSE_FILTER_PASS
	tap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tap.modulate = Color(1, 1, 1, 0)
	tap.pressed.connect(Callable(owner, "select_map_district").bind(district_id))
	panel.add_child(tap)
	return panel

static func _make_vertical_road():
	var road = ColorRect.new()
	road.color = Color("#46545a")
	road.custom_minimum_size = Vector2(15, 126)
	road.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return road

static func _make_horizontal_road():
	var road_panel = PanelContainer.new()
	road_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	road_panel.custom_minimum_size.y = 17
	var road_style = StyleBoxFlat.new()
	road_style.bg_color = Color("#46545a")
	road_panel.add_theme_stylebox_override("panel", road_style)
	var marks = HBoxContainer.new()
	marks.alignment = BoxContainer.ALIGNMENT_CENTER
	marks.add_theme_constant_override("separation", 9)
	road_panel.add_child(marks)
	for i in range(7):
		var dash = ColorRect.new()
		dash.color = Color("#d6bd68")
		dash.custom_minimum_size = Vector2(13, 2)
		dash.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		marks.add_child(dash)
	return road_panel

static func _make_empty_block(owner):
	var empty = PanelContainer.new()
	empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empty.custom_minimum_size = Vector2(0, 126)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#203c38")
	style.border_color = Color("#41645a")
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	empty.add_theme_stylebox_override("panel", style)
	var label = Label.new()
	label.text = owner.PersianText.reshaper("🌳 فضای سبز")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	owner._apply_font(label, 13)
	label.add_theme_color_override("font_color", Color("#a7f3d0"))
	empty.add_child(label)
	return empty

static func _add_map_legend(owner, parent):
	var legend = HBoxContainer.new()
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	legend.add_theme_constant_override("separation", 12)
	legend.custom_minimum_size.y = 29
	parent.add_child(legend)
	var road_text = Label.new()
	road_text.text = owner.PersianText.reshaper("━ خیابان اصلی")
	owner._apply_font(road_text, 11)
	road_text.add_theme_color_override("font_color", Color("#cbd5e1"))
	legend.add_child(road_text)
	var block_text = Label.new()
	block_text.text = owner.PersianText.reshaper("■ محدوده محله")
	owner._apply_font(block_text, 11)
	block_text.add_theme_color_override("font_color", Color("#86efac"))
	legend.add_child(block_text)

static func _add_district_details(owner, district):
	var details = PanelContainer.new()
	details.name = "SelectedDistrictDetails"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#203b50")
	style.border_color = Color("#60a5fa")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	details.add_theme_stylebox_override("panel", style)
	owner.content.add_child(details)

	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 5)
	details.add_child(body)

	var title = Label.new()
	title.text = owner.PersianText.reshaper("📍 جزئیات %s" % str(district.get("name", "محله")))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner._apply_font(title, 17)
	title.add_theme_color_override("font_color", Color("#f8fafc"))
	body.add_child(title)

	var counts = Label.new()
	counts.text = owner.PersianText.reshaper("کل ساختمان‌ها: %d  •  خانه‌ها: %d  •  سایر: %d" % [int(district.get("building_count", 0)), int(district.get("house_count", 0)), int(district.get("other_count", 0)) + int(district.get("emergency_count", 0))])
	counts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	counts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(counts, 13)
	body.add_child(counts)

	var names = district.get("building_names", [])
	var names_label = Label.new()
	names_label.text = owner.PersianText.reshaper("ساختمان‌های این محله: " + ("، ".join(names) if not names.is_empty() else "هنوز ساختمانی ثبت نشده است."))
	names_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	names_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(names_label, 13)
	body.add_child(names_label)

static func _district_color(index):
	var palette = [
		Color("#86c98b"),
		Color("#8bb9d6"),
		Color("#d5b879"),
		Color("#b5a0d8"),
		Color("#7fc6b4"),
		Color("#d99b87")
	]
	return palette[index % palette.size()]
