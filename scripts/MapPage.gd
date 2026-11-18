extends RefCounted

# Lightweight top-down city map. All visuals use native Godot controls.
static func build(owner, city_state):
	var overview = owner.game.get_districts_overview()
	var districts = overview.get("districts", [])
	var industrial = overview.get("industrial_buildings", [])

	owner._add_label("🗺️ نقشه شهر", 24)
	owner._add_label("نمای محله‌ها، خیابان‌ها و محدوده صنعتی شهر", 13)

	var map_panel = PanelContainer.new()
	map_panel.name = "CityMapCanvas"
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var outer = StyleBoxFlat.new()
	outer.bg_color = Color("#142b35")
	outer.border_color = Color("#36515a")
	outer.set_border_width_all(1)
	outer.set_corner_radius_all(18)
	outer.content_margin_left = 8
	outer.content_margin_right = 8
	outer.content_margin_top = 9
	outer.content_margin_bottom = 9
	map_panel.add_theme_stylebox_override("panel", outer)
	owner.content.add_child(map_panel)

	var map_body = VBoxContainer.new()
	map_body.add_theme_constant_override("separation", 0)
	map_panel.add_child(map_body)

	_add_map_header(owner, map_body, districts.size(), industrial.size())
	_add_map_compass(owner, map_body)

	if districts.is_empty():
		_add_empty_city(owner, map_body)
	else:
		var index = 0
		while index < districts.size():
			var street_row = HBoxContainer.new()
			street_row.add_theme_constant_override("separation", 0)
			street_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			map_body.add_child(street_row)

			street_row.add_child(_make_district_block(owner, districts[index], index))
			index += 1
			street_row.add_child(_make_vertical_road())

			if index < districts.size():
				street_row.add_child(_make_district_block(owner, districts[index], index))
				index += 1
			else:
				street_row.add_child(_make_expansion_plot(owner))

			if index < districts.size():
				map_body.add_child(_make_horizontal_road())

		_add_map_legend(owner, map_body)

	_add_industrial_zone(owner, map_body, industrial)

	if owner.selected_map_district_id != "":
		for district in districts:
			if str(district.get("id", "")) == owner.selected_map_district_id:
				_add_district_details(owner, district)
				break


static func _add_map_header(owner, parent, district_count, industrial_count):
	var header = PanelContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#203d46")
	style.set_corner_radius_all(11)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	header.add_theme_stylebox_override("panel", style)
	parent.add_child(header)

	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 7)
	header.add_child(row)

	var live = Label.new()
	live.text = owner.PersianText.reshaper("● زنده")
	live.add_theme_color_override("font_color", Color("#86efac"))
	owner._apply_font(live, 11)
	row.add_child(live)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var count = Label.new()
	count.text = owner.PersianText.reshaper("🏘 %d محله" % district_count)
	count.add_theme_color_override("font_color", Color("#f1f5f9"))
	owner._apply_font(count, 12)
	row.add_child(count)

	var factory_count = Label.new()
	factory_count.text = owner.PersianText.reshaper("🏭 %d صنعتی" % industrial_count)
	factory_count.add_theme_color_override("font_color", Color("#fcd34d"))
	owner._apply_font(factory_count, 12)
	row.add_child(factory_count)


static func _add_map_compass(owner, parent):
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size.y = 27
	parent.add_child(row)
	var label = Label.new()
	label.text = owner.PersianText.reshaper("▲ شمال شهر     ·     نمای هوایی")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#9fb7bd"))
	owner._apply_font(label, 10)
	row.add_child(label)


static func _make_district_block(owner, district, index):
	var district_id = str(district.get("id", ""))
	var selected = district_id == owner.selected_map_district_id
	var panel = PanelContainer.new()
	panel.name = "DistrictTile_" + district_id
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 153)

	var accent = _district_color(index)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#24483f") if index % 2 == 0 else Color("#294d43")
	style.border_color = Color("#facc15") if selected else Color("#54786a")
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(9)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	panel.add_child(stack)

	var heading = HBoxContainer.new()
	heading.add_theme_constant_override("separation", 4)
	stack.add_child(heading)

	var pin = ColorRect.new()
	pin.color = accent
	pin.custom_minimum_size = Vector2(7, 7)
	pin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading.add_child(pin)

	var title = Label.new()
	title.text = owner.PersianText.reshaper(str(district.get("name", "محله " + district_id)))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.clip_text = true
	owner._apply_font(title, 12)
	title.add_theme_color_override("font_color", Color("#f8fafc"))
	heading.add_child(title)

	var count = int(district.get("building_count", 0))
	var houses = int(district.get("house_count", 0))
	var other = int(district.get("other_count", 0)) + int(district.get("emergency_count", 0))
	var stats = Label.new()
	stats.text = owner.PersianText.reshaper("%d ساختمان  ·  %d خانه" % [count, houses])
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owner._apply_font(stats, 10)
	stats.add_theme_color_override("font_color", Color("#d1fae5"))
	stack.add_child(stats)

	# Tiny block plan: lawns with simple building footprints, not image assets.
	var block = PanelContainer.new()
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.custom_minimum_size.y = 63
	var block_style = StyleBoxFlat.new()
	block_style.bg_color = Color("#315d4d")
	block_style.border_color = Color("#416e5d")
	block_style.set_border_width_all(1)
	block_style.set_corner_radius_all(5)
	block.add_theme_stylebox_override("panel", block_style)
	stack.add_child(block)

	var grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 3)
	block.add_child(grid)

	var footprint_count = mini(count, 6)
	for n in range(6):
		if n < footprint_count:
			grid.add_child(_make_building_footprint(n, accent))
		else:
			grid.add_child(_make_green_plot(n))

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


static func _make_building_footprint(index, accent):
	var building = Panel.new()
	building.custom_minimum_size = Vector2(0, 24)
	var style = StyleBoxFlat.new()
	var shades = [Color("#d8c9a5"), Color("#b9cbd2"), Color("#d7b58b"), Color("#c3b7d9")]
	style.bg_color = shades[index % shades.size()]
	style.border_color = accent.darkened(0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 2
	style.content_margin_right = 2
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	building.add_theme_stylebox_override("panel", style)
	return building


static func _make_green_plot(index):
	var plot = Panel.new()
	plot.custom_minimum_size = Vector2(0, 24)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#3d755b") if index % 2 == 0 else Color("#477f62")
	style.set_corner_radius_all(3)
	plot.add_theme_stylebox_override("panel", style)
	return plot


static func _make_vertical_road():
	var road = ColorRect.new()
	road.color = Color("#53636a")
	road.custom_minimum_size = Vector2(17, 153)
	road.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return road


static func _make_horizontal_road():
	var road = PanelContainer.new()
	road.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	road.custom_minimum_size.y = 19
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#53636a")
	road.add_theme_stylebox_override("panel", style)
	var lane = HBoxContainer.new()
	lane.alignment = BoxContainer.ALIGNMENT_CENTER
	lane.add_theme_constant_override("separation", 12)
	road.add_child(lane)
	for i in range(8):
		var dash = ColorRect.new()
		dash.color = Color("#e5cf83")
		dash.custom_minimum_size = Vector2(12, 2)
		dash.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lane.add_child(dash)
	return road


static func _make_expansion_plot(owner):
	var plot = PanelContainer.new()
	plot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plot.custom_minimum_size = Vector2(0, 153)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#203f38")
	style.border_color = Color("#416b5b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	plot.add_theme_stylebox_override("panel", style)
	var label = Label.new()
	label.text = owner.PersianText.reshaper("🌳\nزمین توسعه\n\nآماده ساخت")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(label, 11)
	label.add_theme_color_override("font_color", Color("#a7f3d0"))
	plot.add_child(label)
	return plot


static func _add_empty_city(owner, parent):
	var empty = PanelContainer.new()
	empty.custom_minimum_size.y = 205
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#24483f")
	style.border_color = Color("#527565")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	empty.add_theme_stylebox_override("panel", style)
	parent.add_child(empty)
	var label = Label.new()
	label.text = owner.PersianText.reshaper("🌱\n\nزمین شهر آماده توسعه است\n\nبا ساخت اولین ساختمان، محله‌ها و خیابان‌ها روی نقشه شکل می‌گیرند.")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(label, 13)
	label.add_theme_color_override("font_color", Color("#d1fae5"))
	empty.add_child(label)


static func _add_industrial_zone(owner, parent, industrial):
	var zone = PanelContainer.new()
	zone.name = "IndustrialMapZone"
	zone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#3b4144")
	style.border_color = Color("#8b7650")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	zone.add_theme_stylebox_override("panel", style)
	parent.add_child(zone)

	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 5)
	zone.add_child(body)

	var heading = Label.new()
	heading.text = owner.PersianText.reshaper("🏭 منطقه صنعتی خارج از محدوده مسکونی")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner._apply_font(heading, 12)
	heading.add_theme_color_override("font_color", Color("#fcd34d"))
	body.add_child(heading)

	var sub = Label.new()
	sub.text = owner.PersianText.reshaper("%d سازه صنعتی" % industrial.size() if not industrial.is_empty() else "هنوز سازه‌ای در این محدوده ساخته نشده است.")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner._apply_font(sub, 10)
	sub.add_theme_color_override("font_color", Color("#e2e8f0"))
	body.add_child(sub)

	if not industrial.is_empty():
		var names = Label.new()
		names.text = owner.PersianText.reshaper("  •  ".join(industrial))
		names.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		names.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		owner._apply_font(names, 11)
		names.add_theme_color_override("font_color", Color("#f1f5f9"))
		body.add_child(names)


static func _add_map_legend(owner, parent):
	var legend = HBoxContainer.new()
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	legend.add_theme_constant_override("separation", 10)
	legend.custom_minimum_size.y = 28
	parent.add_child(legend)
	var road = Label.new()
	road.text = owner.PersianText.reshaper("━ خیابان")
	owner._apply_font(road, 10)
	road.add_theme_color_override("font_color", Color("#cbd5e1"))
	legend.add_child(road)
	var buildings = Label.new()
	buildings.text = owner.PersianText.reshaper("■ ساختمان")
	owner._apply_font(buildings, 10)
	buildings.add_theme_color_override("font_color", Color("#e5d4b5"))
	legend.add_child(buildings)
	var green = Label.new()
	green.text = owner.PersianText.reshaper("■ فضای سبز")
	owner._apply_font(green, 10)
	green.add_theme_color_override("font_color", Color("#86efac"))
	legend.add_child(green)


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
	owner._apply_font(title, 16)
	title.add_theme_color_override("font_color", Color("#f8fafc"))
	body.add_child(title)

	var counts = Label.new()
	counts.text = owner.PersianText.reshaper("کل ساختمان‌ها: %d  •  خانه‌ها: %d  •  سایر: %d" % [int(district.get("building_count", 0)), int(district.get("house_count", 0)), int(district.get("other_count", 0)) + int(district.get("emergency_count", 0))])
	counts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	counts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(counts, 12)
	body.add_child(counts)

	var names = district.get("building_names", [])
	var names_label = Label.new()
	names_label.text = owner.PersianText.reshaper("ساختمان‌های این محله: " + ("، ".join(names) if not names.is_empty() else "هنوز ساختمانی ثبت نشده است."))
	names_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	names_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(names_label, 12)
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
