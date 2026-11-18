extends RefCounted

# Lightweight city map: districts remain data-driven, while each building is
# represented by a tappable, category-coloured point.
static func build(owner, city_state):
	var overview = owner.game.get_districts_overview()
	var districts = overview.get("districts", [])
	var industrial = _collect_industrial_buildings(owner)

	owner._add_label("🗺️ نقشه شهر", 24)
	owner._add_label("هر نقطه یک ساختمان است؛ برای دیدن جزئیات روی آن بزن.", 13)

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
	map_body.add_theme_constant_override("separation", 7)
	map_panel.add_child(map_body)

	_add_map_header(owner, map_body, districts.size(), _count_all_buildings(owner))
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
	_add_street_furniture(owner, map_body)

	_add_industrial_zone(owner, map_body, industrial)

	if owner.selected_map_district_id != "":
		for district in districts:
			if str(district.get("id", "")) == owner.selected_map_district_id:
				_add_district_details(owner, district)
				break

	if owner.selected_map_building_data is Dictionary and not owner.selected_map_building_data.is_empty():
		_add_building_details(owner, owner.selected_map_building_data)


static func _add_map_header(owner, parent, district_count, building_count):
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

	var buildings = Label.new()
	buildings.text = owner.PersianText.reshaper("● %d ساختمان" % building_count)
	buildings.add_theme_color_override("font_color", Color("#cbd5e1"))
	owner._apply_font(buildings, 12)
	row.add_child(buildings)


static func _add_map_compass(owner, parent):
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size.y = 22
	parent.add_child(row)
	var label = Label.new()
	label.text = owner.PersianText.reshaper("▲ شمال شهر     ·     نقشه محله‌ای")
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
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

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
	stack.add_theme_constant_override("separation", 5)
	panel.add_child(stack)

	var heading = HBoxContainer.new()
	heading.add_theme_constant_override("separation", 4)
	stack.add_child(heading)

	var pin = ColorRect.new()
	pin.color = accent
	pin.custom_minimum_size = Vector2(7, 7)
	pin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading.add_child(pin)

	var title_button = Button.new()
	title_button.text = owner.PersianText.reshaper(str(district.get("name", "محله " + district_id)))
	title_button.flat = true
	title_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title_button.add_theme_color_override("font_color", Color("#f8fafc"))
	owner._apply_font(title_button, 12)
	title_button.pressed.connect(Callable(owner, "select_map_district").bind(district_id))
	heading.add_child(title_button)

	var buildings = _collect_district_buildings(owner, district_id)
	var stats = Label.new()
	stats.text = owner.PersianText.reshaper("%d نقطه ساختمانی" % buildings.size())
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owner._apply_font(stats, 10)
	stats.add_theme_color_override("font_color", Color("#d1fae5"))
	stack.add_child(stats)

	var point_grid = GridContainer.new()
	point_grid.name = "BuildingPointGrid_" + district_id
	point_grid.columns = 5
	point_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	point_grid.add_theme_constant_override("h_separation", 4)
	point_grid.add_theme_constant_override("v_separation", 4)
	stack.add_child(point_grid)

	if buildings.is_empty():
		var empty = Label.new()
		empty.text = owner.PersianText.reshaper("زمین آماده ساخت")
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		owner._apply_font(empty, 10)
		empty.add_theme_color_override("font_color", Color("#a7f3d0"))
		point_grid.add_child(empty)
	else:
		for building in buildings:
			point_grid.add_child(_make_building_dot(owner, building))

	return panel


static func _make_building_dot(owner, building):
	var dot = Button.new()
	dot.name = "BuildingDot_" + str(building.get("map_key", "unknown"))
	dot.text = "●"
	dot.tooltip_text = str(building.get("name", "ساختمان"))
	dot.custom_minimum_size = Vector2(30, 30)
	dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.flat = false
	dot.focus_mode = Control.FOCUS_NONE
	dot.add_theme_font_size_override("font_size", 21)
	var tint = _building_color(str(building.get("building_id", "")), str(building.get("category", "")))
	dot.add_theme_color_override("font_color", tint)
	dot.add_theme_color_override("font_hover_color", tint.lightened(0.25))
	dot.add_theme_color_override("font_pressed_color", tint.darkened(0.2))
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color("#17372f")
	normal.border_color = tint.darkened(0.25)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(15)
	dot.add_theme_stylebox_override("normal", normal)
	var hover = normal.duplicate()
	hover.bg_color = Color("#31574b")
	hover.border_color = tint.lightened(0.2)
	dot.add_theme_stylebox_override("hover", hover)
	var pressed = normal.duplicate()
	pressed.bg_color = Color("#0f2924")
	dot.add_theme_stylebox_override("pressed", pressed)
	dot.pressed.connect(Callable(owner, "select_map_building").bind(building))
	return dot


static func _collect_district_buildings(owner, district_id):
	var result = []
	var state = owner.game.state
	var definitions = owner.game.get_building_definitions()

	for i in range(state.get("buildings", []).size()):
		var building = state.buildings[i]
		if str(building.get("district_id", "")) != district_id:
			continue
		var building_id = str(building.get("id", ""))
		var definition = definitions.get(building_id, {})
		result.append(_make_map_record(
			"building_%d" % i, building_id,
			str(definition.get("name", "ساختمان")), str(definition.get("category", "")),
			district_id, "ساخته‌شده", int(building.get("workers", 0)),
			int(building.get("balance", 0)), building
		))

	for i in range(state.get("constructions", []).size()):
		var construction = state.constructions[i]
		if str(construction.get("district_id", "")) != district_id:
			continue
		var building_id = str(construction.get("id", ""))
		var definition = definitions.get(building_id, {})
		result.append(_make_map_record(
			"construction_%d" % i, building_id,
			str(definition.get("name", "پروژه ساختمانی")), str(definition.get("category", "")),
			district_id, "در حال ساخت", 0, 0, construction
		))

	for i in range(state.get("private_businesses", []).size()):
		var business = state.private_businesses[i]
		if bool(business.get("rented_municipal", false)) or str(business.get("district_id", "")) != district_id:
			continue
		var building_id = str(business.get("building_id", ""))
		var definition = definitions.get(building_id, {})
		result.append(_make_map_record(
			"business_%d" % i, building_id,
			str(business.get("name", definition.get("name", "کسب‌وکار"))), str(definition.get("category", "کسب‌وکارها")),
			district_id, "کسب‌وکار خصوصی", int(business.get("workers", 0)),
			int(business.get("balance", 0)), business
		))
	return result


static func _collect_industrial_buildings(owner):
	var result = []
	var state = owner.game.state
	var definitions = owner.game.get_building_definitions()
	for i in range(state.get("buildings", []).size()):
		var building = state.buildings[i]
		if str(building.get("zone", "")) != "industrial":
			continue
		var building_id = str(building.get("id", ""))
		var definition = definitions.get(building_id, {})
		result.append(_make_map_record("industrial_%d" % i, building_id,
			str(definition.get("name", "ساختمان صنعتی")), str(definition.get("category", "")),
			"منطقه صنعتی", "ساخته‌شده", int(building.get("workers", 0)),
			int(building.get("balance", 0)), building))
	for i in range(state.get("constructions", []).size()):
		var construction = state.constructions[i]
		if str(construction.get("zone", "")) != "industrial":
			continue
		var building_id = str(construction.get("id", ""))
		var definition = definitions.get(building_id, {})
		result.append(_make_map_record("industrial_project_%d" % i, building_id,
			str(definition.get("name", "پروژه صنعتی")), str(definition.get("category", "")),
			"منطقه صنعتی", "در حال ساخت", 0, 0, construction))
	for i in range(state.get("private_businesses", []).size()):
		var business = state.private_businesses[i]
		if bool(business.get("rented_municipal", false)) or str(business.get("zone", "")) != "industrial":
			continue
		var building_id = str(business.get("building_id", ""))
		var definition = definitions.get(building_id, {})
		result.append(_make_map_record("industrial_business_%d" % i, building_id,
			str(business.get("name", "کسب‌وکار صنعتی")), str(definition.get("category", "")),
			"منطقه صنعتی", "کسب‌وکار خصوصی", int(business.get("workers", 0)),
			int(business.get("balance", 0)), business))
	return result


static func _make_map_record(map_key, building_id, building_name, category, district_id, status, workers, balance, source):
	return {
		"map_key": map_key,
		"building_id": building_id,
		"name": building_name,
		"category": category,
		"district_id": district_id,
		"status": status,
		"workers": workers,
		"balance": balance,
		"jobs": int(source.get("jobs", 0)),
		"finish_at": int(source.get("finish_at", 0))
	}


static func _count_all_buildings(owner):
	var state = owner.game.state
	return state.get("buildings", []).size() + state.get("constructions", []).size() + state.get("private_businesses", []).size()


static func _add_map_legend(owner, parent):
	var legend_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#1c3940")
	style.set_corner_radius_all(9)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	legend_panel.add_theme_stylebox_override("panel", style)
	parent.add_child(legend_panel)
	var legend = GridContainer.new()
	legend.columns = 3
	legend.add_theme_constant_override("h_separation", 9)
	legend.add_theme_constant_override("v_separation", 5)
	legend_panel.add_child(legend)
	_add_legend_item(owner, legend, "#ef5350", "مسکونی")
	_add_legend_item(owner, legend, "#f59e0b", "تجاری")
	_add_legend_item(owner, legend, "#3b82f6", "صنعتی")
	_add_legend_item(owner, legend, "#22c55e", "خدمات شهری")
	_add_legend_item(owner, legend, "#a78bfa", "انبار و حمل‌ونقل")
	_add_legend_item(owner, legend, "#94a3b8", "سایر")


static func _add_legend_item(owner, parent, hex_color, label_text):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	parent.add_child(row)
	var dot = Label.new()
	dot.text = "●"
	dot.add_theme_color_override("font_color", Color(hex_color))
	owner._apply_font(dot, 14)
	row.add_child(dot)
	var label = Label.new()
	label.text = owner.PersianText.reshaper(label_text)
	owner._apply_font(label, 9)
	label.add_theme_color_override("font_color", Color("#e2e8f0"))
	row.add_child(label)



static func _add_street_furniture(owner, parent):
	var strip = PanelContainer.new()
	strip.name = "CityStreetFurniture"
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.add_theme_stylebox_override("panel", _road_style("#203b3b", "#41615b", 8))
	parent.add_child(strip)
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	strip.add_child(row)
	_add_street_item(owner, row, "🌳", "درختان خیابانی", "#86c98b")
	_add_street_item(owner, row, "🚦", "چراغ راهنمایی", "#fbbf24")
	_add_street_item(owner, row, "🚶", "پیاده‌رو", "#cbd5e1")


static func _add_street_item(owner, parent, symbol, title_text, tint):
	var item = HBoxContainer.new()
	item.add_theme_constant_override("separation", 3)
	parent.add_child(item)
	var icon = Label.new()
	icon.text = symbol
	owner._apply_font(icon, 13)
	icon.add_theme_color_override("font_color", Color(tint))
	item.add_child(icon)
	var label = Label.new()
	label.text = owner.PersianText.reshaper(title_text)
	owner._apply_font(label, 9)
	label.add_theme_color_override("font_color", Color("#dbe7e4"))
	item.add_child(label)

static func _add_industrial_zone(owner, parent, industrial):
	var zone = PanelContainer.new()
	zone.name = "IndustrialMapZone"
	zone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#303b49")
	style.border_color = Color("#3b82f6")
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
	heading.text = owner.PersianText.reshaper("🏭 منطقه صنعتی")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner._apply_font(heading, 12)
	heading.add_theme_color_override("font_color", Color("#93c5fd"))
	body.add_child(heading)

	var sub = Label.new()
	sub.text = owner.PersianText.reshaper("%d نقطه صنعتی" % industrial.size() if not industrial.is_empty() else "هنوز سازه‌ای در این محدوده ساخته نشده است.")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner._apply_font(sub, 10)
	sub.add_theme_color_override("font_color", Color("#e2e8f0"))
	body.add_child(sub)

	if not industrial.is_empty():
		var points = GridContainer.new()
		points.name = "IndustrialBuildingPoints"
		points.columns = 6
		points.add_theme_constant_override("h_separation", 4)
		points.add_theme_constant_override("v_separation", 4)
		body.add_child(points)
		for building in industrial:
			points.add_child(_make_building_dot(owner, building))


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
	label.text = owner.PersianText.reshaper("🌱\n\nزمین شهر آماده توسعه است\n\nبا ساخت اولین ساختمان، نقطه‌های رنگی روی نقشه ظاهر می‌شوند.")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(label, 13)
	label.add_theme_color_override("font_color", Color("#d1fae5"))
	empty.add_child(label)


static func _make_vertical_road():
	var road = PanelContainer.new()
	road.name = "CityRoadVertical"
	road.custom_minimum_size = Vector2(34, 90)
	road.size_flags_vertical = Control.SIZE_EXPAND_FILL
	road.add_theme_stylebox_override("panel", _road_style("#34434c", "#81909a", 2))
	var cross_section = HBoxContainer.new()
	cross_section.add_theme_constant_override("separation", 0)
	road.add_child(cross_section)
	cross_section.add_child(_make_sidewalk(true))
	var lane = VBoxContainer.new()
	lane.name = "RoadLaneVertical"
	lane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lane.add_theme_constant_override("separation", 5)
	lane.alignment = BoxContainer.ALIGNMENT_CENTER
	cross_section.add_child(lane)
	for i in range(5):
		var dash = ColorRect.new()
		dash.color = Color("#e6c96f")
		dash.custom_minimum_size = Vector2(2, 9)
		dash.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		lane.add_child(dash)
	cross_section.add_child(_make_sidewalk(true))
	var crossing = _make_crosswalk(true)
	crossing.name = "RoadCrosswalkVertical"
	road.add_child(crossing)
	return road


static func _make_horizontal_road():
	var road = PanelContainer.new()
	road.name = "CityRoadHorizontal"
	road.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	road.custom_minimum_size.y = 34
	road.add_theme_stylebox_override("panel", _road_style("#34434c", "#81909a", 2))
	var cross_section = VBoxContainer.new()
	cross_section.add_theme_constant_override("separation", 0)
	road.add_child(cross_section)
	cross_section.add_child(_make_sidewalk(false))
	var lane = HBoxContainer.new()
	lane.name = "RoadLaneHorizontal"
	lane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lane.add_theme_constant_override("separation", 8)
	lane.alignment = BoxContainer.ALIGNMENT_CENTER
	cross_section.add_child(lane)
	for i in range(9):
		var dash = ColorRect.new()
		dash.color = Color("#e6c96f")
		dash.custom_minimum_size = Vector2(10, 2)
		dash.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lane.add_child(dash)
	cross_section.add_child(_make_sidewalk(false))
	var crossing = _make_crosswalk(false)
	crossing.name = "RoadCrosswalkHorizontal"
	road.add_child(crossing)
	return road


static func _road_style(fill_color, border_color, radius):
	var style = StyleBoxFlat.new()
	style.bg_color = Color(fill_color)
	style.border_color = Color(border_color)
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 2
	style.content_margin_right = 2
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


static func _make_sidewalk(vertical):
	var sidewalk = ColorRect.new()
	sidewalk.color = Color("#9aa5a8")
	if vertical:
		sidewalk.custom_minimum_size.x = 5
		sidewalk.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		sidewalk.custom_minimum_size.y = 5
		sidewalk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sidewalk


static func _make_crosswalk(vertical):
	var crossing = HBoxContainer.new() if vertical else VBoxContainer.new()
	crossing.name = "RoadCrosswalk"
	crossing.alignment = BoxContainer.ALIGNMENT_CENTER
	crossing.add_theme_constant_override("separation", 3)
	crossing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(5):
		var stripe = ColorRect.new()
		stripe.color = Color("#e8edf0")
		if vertical:
			stripe.custom_minimum_size = Vector2(3, 10)
		else:
			stripe.custom_minimum_size = Vector2(10, 3)
		crossing.add_child(stripe)
	return crossing


static func _make_expansion_plot(owner):
	var plot = PanelContainer.new()
	plot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plot.custom_minimum_size = Vector2(0, 90)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#203f38")
	style.border_color = Color("#416b5b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	plot.add_theme_stylebox_override("panel", style)
	var label = Label.new()
	label.text = owner.PersianText.reshaper("🌳\nزمین توسعه")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	owner._apply_font(label, 10)
	label.add_theme_color_override("font_color", Color("#a7f3d0"))
	plot.add_child(label)
	return plot


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


static func _add_building_details(owner, building):
	var details = PanelContainer.new()
	details.name = "SelectedMapBuildingDetails"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#203b50")
	style.border_color = _building_color(str(building.get("building_id", "")), str(building.get("category", "")))
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	details.add_theme_stylebox_override("panel", style)
	owner.content.add_child(details)
	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
	details.add_child(body)
	var title = Label.new()
	title.text = owner.PersianText.reshaper("📍 " + str(building.get("name", "ساختمان")))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner._apply_font(title, 16)
	title.add_theme_color_override("font_color", Color("#f8fafc"))
	body.add_child(title)
	_add_detail_line(owner, body, "محله", str(building.get("district_id", "—")))
	_add_detail_line(owner, body, "وضعیت", str(building.get("status", "—")))
	if str(building.get("status", "")) != "در حال ساخت":
		_add_detail_line(owner, body, "کارگر", str(building.get("workers", 0)))
		_add_detail_line(owner, body, "موجودی حساب", str(building.get("balance", 0)))
	var close = Button.new()
	close.text = owner.PersianText.reshaper("بستن جزئیات")
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(Callable(owner, "clear_selected_map_building"))
	owner._apply_font(close, 11)
	body.add_child(close)


static func _add_detail_line(owner, parent, caption, value):
	var line = Label.new()
	line.text = owner.PersianText.reshaper("%s: %s" % [caption, value])
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(line, 12)
	line.add_theme_color_override("font_color", Color("#dbeafe"))
	parent.add_child(line)


static func _building_color(building_id, category):
	if building_id in ["small_house", "normal_house", "low_apartment", "high_apartment", "residential_tower"]:
		return Color("#ef5350")
	if category in ["کسب‌وکارها"] or building_id in ["grocery_store", "bakery", "restaurant", "shopping_mall", "fish_market", "mineral_market"]:
		return Color("#f59e0b")
	if category in ["کارخانه‌ها", "معادن", "کشاورزی"] or building_id in ["factory", "woodcutter", "sawmill", "carpenter", "stone_mine", "iron_mine", "fish_processing_plant"]:
		return Color("#3b82f6")
	if category in ["خدمات شهری", "تفریح و فرهنگ"]:
		return Color("#22c55e")
	if category in ["انبارها", "حمل‌ونقل"]:
		return Color("#a78bfa")
	return Color("#94a3b8")


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
