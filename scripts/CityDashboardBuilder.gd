extends RefCounted

# Shared dashboard and city-information UI builders.

static func _add_home_services_panel(owner, city_state):
	var compact = owner.get_viewport_rect().size.x < 900
	var panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("#172235")
	panel_style.border_color = Color("#475569")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	owner.content.add_child(panel)
	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 9)
	panel.add_child(body)

	var total_coverage = 0
	var service_count = owner.game.SERVICE_GROUPS.size()
	for service_id in owner.game.SERVICE_GROUPS.keys():
		total_coverage += int(city_state.get("services", {}).get(service_id, 0))
	var average_coverage = int(round(float(total_coverage) / float(max(1, service_count))))
	var header = Button.new()
	header.text = owner.PersianText.reshaper(("%s  🏙️  خدمات شهری" % ("▼" if owner.home_city_details_expanded else "▶")) + "     میانگین پوشش: %d%%" % average_coverage)
	header.custom_minimum_size = Vector2(0, 82 if owner.get_viewport_rect().size.x < 500.0 else (62 if compact else 54))
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner._apply_font(header, 19 if compact else 17)
	owner._style_button(header, false)
	header.connect("pressed", Callable(owner, "toggle_home_city_details"))
	body.add_child(header)

	var hint = Label.new()
	hint.text = owner.PersianText.reshaper("وضعیت آب، برق، درمان، امنیت و امکانات شهر را یک‌جا ببین.")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(hint, 15 if compact else 14)
	hint.add_theme_color_override("font_color", Color("#cbd5e1"))
	body.add_child(hint)

	if not owner.home_city_details_expanded:
		return

	var section_line = HSeparator.new()
	body.add_child(section_line)
	var section_title = Label.new()
	section_title.text = owner.PersianText.reshaper("شاخص خدمات شهری")
	section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner._apply_font(section_title, 18)
	section_title.add_theme_color_override("font_color", Color("#f8fafc"))
	body.add_child(section_title)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(grid)
	var service_order = ["food","water","power","health","education","safety","leisure","sanitation"]
	for service_id in service_order:
		if not owner.game.SERVICE_GROUPS.has(service_id):
			continue
		var service_data = owner.game.SERVICE_GROUPS[service_id]
		var coverage = int(clamp(int(city_state.get("services", {}).get(service_id, 0)), 0, 100))
		var need = int(clamp(int(city_state.get("needs", {}).get(service_id, 60)), 0, 100))
		var building_total = 0
		for building_id in service_data.get("buildings", []):
			building_total += owner.game.get_building_count(str(building_id))
		owner._add_service_metric_card(grid, str(service_data.get("name", service_id)), coverage, need, building_total, compact)

	var road_title = Label.new()
	road_title.text = owner.PersianText.reshaper("پوشش جاده‌ای")
	road_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner._apply_font(road_title, 18)
	road_title.add_theme_color_override("font_color", Color("#f8fafc"))
	body.add_child(road_title)

	# Road coverage is represented by the current road-network development level.
	# Each of the three upgrade levels contributes one third of the indicator.
	var road_level = int(clamp(int(city_state.get("road_level", 1)), 0, 3))
	var road_coverage = int(round(float(road_level) * 100.0 / 3.0))
	var road_status = Label.new()
	road_status.text = owner.PersianText.reshaper("توسعه شبکه جاده‌ای: %d٪  |  سطح %d از ۳" % [road_coverage, road_level])
	road_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner._apply_font(road_status, 15)
	road_status.add_theme_color_override("font_color", Color("#86efac") if road_coverage >= 70 else (Color("#fcd34d") if road_coverage >= 40 else Color("#fca5a5")))
	body.add_child(road_status)

	var road_bar = ProgressBar.new()
	road_bar.min_value = 0
	road_bar.max_value = 100
	road_bar.value = road_coverage
	road_bar.show_percentage = false
	road_bar.custom_minimum_size = Vector2(0, 9)
	var road_fill = StyleBoxFlat.new()
	road_fill.bg_color = Color("#22c55e") if road_coverage >= 70 else (Color("#f59e0b") if road_coverage >= 40 else Color("#ef4444"))
	road_fill.set_corner_radius_all(4)
	road_bar.add_theme_stylebox_override("fg", road_fill)
	var road_track = StyleBoxFlat.new()
	road_track.bg_color = Color("#334155")
	road_track.set_corner_radius_all(4)
	road_bar.add_theme_stylebox_override("bg", road_track)
	body.add_child(road_bar)

	var infra_title = Label.new()
	infra_title.text = owner.PersianText.reshaper("زیرساخت‌های پشتیبان")
	infra_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner._apply_font(infra_title, 18)
	infra_title.add_theme_color_override("font_color", Color("#f8fafc"))
	body.add_child(infra_title)
	var central_bank_status = "فعال" if owner.game.has_central_bank() else ("بازسازی: %d روز" % int(city_state.get("central_bank_rebuild_days_left", 0)) if int(city_state.get("central_bank_rebuild_days_left", 0)) > 0 else "ساخته نشده")
	var infrastructure_text = "ساختمان‌ها: %d   |   ظرفیت انبار: %d\nبانک مرکزی: %s   |   بانک شهری: %d\nجنگل: %d/۱۰۰ درخت   |   معادن فعال: %d" % [city_state.buildings.size(), owner.game.get_storage_capacity(), central_bank_status, owner.game.get_building_count("municipal_bank"), owner.game.get_forest_tree_count(), owner._active_mine_count()]
	var infra_label = Label.new()
	infra_label.text = owner.PersianText.reshaper(infrastructure_text)
	infra_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	infra_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	infra_label.custom_minimum_size = Vector2(0, 76 if compact else 64)
	owner._apply_font(infra_label, 16 if compact else 15)
	infra_label.add_theme_color_override("font_color", Color("#dbeafe"))
	body.add_child(infra_label)

static func _add_service_metric_card(owner, parent, title_text, coverage, need, building_count, compact):
	var card = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color("#202f43")
	card_style.border_color = Color("#3b4b61")
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(9)
	card_style.content_margin_left = 8
	card_style.content_margin_right = 8
	card_style.content_margin_top = 8
	card_style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", card_style)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	card.add_child(stack)

	var title = Label.new()
	title.text = owner.PersianText.reshaper("%s  (%d ساختمان)" % [title_text, building_count])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(0, 52 if owner.get_viewport_rect().size.x < 500.0 else (38 if compact else 32))
	owner._apply_font(title, 16 if compact else 15)
	title.add_theme_color_override("font_color", Color("#f8fafc"))
	stack.add_child(title)

	var coverage_label = Label.new()
	coverage_label.text = owner.PersianText.reshaper("پوشش خدمات: %d٪" % coverage)
	coverage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner._apply_font(coverage_label, 15)
	coverage_label.add_theme_color_override("font_color", Color("#86efac") if coverage >= 70 else (Color("#fcd34d") if coverage >= 40 else Color("#fca5a5")))
	stack.add_child(coverage_label)

	var coverage_bar = ProgressBar.new()
	coverage_bar.min_value = 0
	coverage_bar.max_value = 100
	coverage_bar.value = coverage
	coverage_bar.show_percentage = false
	coverage_bar.custom_minimum_size = Vector2(0, 9)
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color("#22c55e") if coverage >= 70 else (Color("#f59e0b") if coverage >= 40 else Color("#ef4444"))
	fill.set_corner_radius_all(4)
	coverage_bar.add_theme_stylebox_override("fg", fill)
	var track = StyleBoxFlat.new()
	track.bg_color = Color("#334155")
	track.set_corner_radius_all(4)
	coverage_bar.add_theme_stylebox_override("bg", track)
	stack.add_child(coverage_bar)

	var need_label = Label.new()
	need_label.text = owner.PersianText.reshaper("رضایت از این نیاز: %d٪" % need)
	need_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner._apply_font(need_label, 14)
	need_label.add_theme_color_override("font_color", Color("#cbd5e1"))
	stack.add_child(need_label)

static func _service_summary(owner):
	var parts = []
	for id in owner.game.SERVICE_GROUPS.keys():
		var label = str(owner.game.SERVICE_GROUPS[id].name)
		parts.append("%s %d%%" % [label, int(owner.game.state.get("services",{}).get(id,0))])
	return " | ".join(parts)

static func _needs_summary(owner):
	var labels = {"food":"خوراک","water":"آب","power":"برق","health":"سلامت","education":"آموزش","safety":"امنیت","leisure":"تفریح","sanitation":"بهداشت"}
	var parts = []
	for id in labels.keys():
		parts.append("%s %d%%" % [labels[id], int(owner.game.state.get("needs",{}).get(id,60))])
	return " | ".join(parts)

static func _active_mine_count(owner):
	var count = 0
	for mine in owner.game.get_mines():
		if bool(mine.get("active", false)):
			count += 1
	return count

static func _sort_building_ids_by_unlock_priority(owner, a, b):
	var definitions = owner.game.get_building_definitions()
	var first = definitions[str(a)]
	var second = definitions[str(b)]
	var first_level = int(first.get("level_unlock", 1))
	var second_level = int(second.get("level_unlock", 1))
	if first_level != second_level:
		return first_level < second_level
	var first_population = int(first.get("unlock", 0))
	var second_population = int(second.get("unlock", 0))
	if first_population != second_population:
		return first_population < second_population
	var first_cost = int(first.get("cost", 0))
	var second_cost = int(second.get("cost", 0))
	if first_cost != second_cost:
		return first_cost < second_cost
	return str(first.get("name", a)) < str(second.get("name", b))

static func _add_building_category_items(owner, category):
	var visible_buildings = 0
	var definitions = owner.game.get_building_definitions()
	var building_ids = []
	for id in definitions.keys():
		var data = definitions[id]
		if str(id) == "fish_lake":
			continue
		if category == "همه" and str(data.get("category","")) == "حمل‌ونقل":
			continue
		if category == "ماهیگیری" and not str(id) in ["fish_lake","fishing_dock","fish_market","fish_processing_plant"]:
			continue
		if category != "همه" and category != "ماهیگیری" and str(data.get("category","")) != category:
			continue
		building_ids.append(str(id))
	building_ids.sort_custom(Callable(owner, "_sort_building_ids_by_unlock_priority"))
	for id in building_ids:
		# Keep the building option visible while another copy is under construction.
		# The construction capacity and economy checks remain enforced by build().
		var data = definitions[id]
		visible_buildings += 1
		var s = owner.game.state
		var population_unlocked = int(s.population) >= int(data.get("unlock", 0))
		var required_level = int(data.get("level_unlock", 1))
		var level_unlocked = int(s.level) >= required_level
		var unlocked = population_unlocked and level_unlocked
		var label = "%s%s | هزینه: %d | زمین: %d قطعه | جمعیت: %d | سطح: %d" % [data.name, "" if unlocked else " 🔒", data.cost,owner.game.get_land_size(id),data.unlock,required_level]
		var building_button = owner._add_button(label, owner, "build_building", [id])
		building_button.name = "BuildingOption_" + id
		# Locked buildings stay tappable so their exact unlock requirements can be explained.
		building_button.disabled = false
		if id == owner.mission_target_building_id:
			building_button.modulate = Color("#fde68a")
			building_button.name = "MissionTargetBuilding"
			owner.mission_target_building_button = building_button
	if visible_buildings == 0:
		owner._add_label("در این دسته ساختمانی تعریف نشده است.", 16)

static func _resource_summary(owner):
	var parts = []
	for id in owner.game.get_resource_definitions().keys():
		parts.append("%s: %d" % [owner.game.get_resource_definitions()[id].name,owner.game.state.resources.get(id,0)])
	return " | ".join(parts)
