extends RefCounted

# Builds construction categories, building options, districts, and mines.
static func build(owner, s):
	var game = owner.game
	owner._add_label("ساخت‌وساز شهر", 22)
	var building_groups = {
		"مسکونی":["خانه‌ها"],
		"انبارها":["انبارها"],
		"اقتصادی":["کشاورزی","ماهیگیری","معادن","کارخانه‌ها","کسب‌وکارها"],
		"عمومی":["خدمات شهری","تفریح و فرهنگ"]
	}
	owner._add_label("گروه ساختمان‌ها | برای دیدن زیرگروه‌ها انتخاب کن", 19)
	var building_group_icons = {"مسکونی":"🏠", "انبارها":"📦", "اقتصادی":"🏭", "عمومی":"🏛️"}
	for group_name in ["مسکونی","انبارها","اقتصادی","عمومی"]:
		var group_expanded = owner.selected_building_group == group_name
		var group_button = owner._add_button(("▼  " if group_expanded else "＋  ") + building_group_icons[group_name] + "  " + group_name + ("  |  انتخاب‌شده" if group_expanded else ""), owner, "select_building_group", [group_name])
		group_button.custom_minimum_size.y = 76 if owner.get_viewport_rect().size.x < 900 else 66
		var group_normal = Color("#263b52") if group_expanded else Color("#30343a")
		var group_hover = Color("#345574") if group_expanded else Color("#454b53")
		var group_pressed = Color("#1d3043") if group_expanded else Color("#20252b")
		group_button.add_theme_stylebox_override("normal", owner._button_style(group_normal, Color("#fbbf24") if group_expanded else Color("#7b8794")))
		group_button.add_theme_stylebox_override("hover", owner._button_style(group_hover, Color("#fcd34d") if group_expanded else Color("#cbd5e1")))
		group_button.add_theme_stylebox_override("focus", owner._button_style(group_hover, Color("#fcd34d") if group_expanded else Color("#cbd5e1")))
		group_button.add_theme_stylebox_override("pressed", owner._button_style(group_pressed, Color("#fbbf24")))
		group_button.add_theme_color_override("font_color", Color("#ffffff"))
		group_button.add_theme_color_override("font_color_hover", Color("#ffffff"))
		if group_expanded:
			var subgroup_panel = PanelContainer.new()
			subgroup_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var subgroup_style = StyleBoxFlat.new()
			subgroup_style.bg_color = Color("#172536")
			subgroup_style.border_color = Color("#60a5fa")
			subgroup_style.set_border_width_all(2)
			subgroup_style.set_corner_radius_all(12)
			subgroup_style.content_margin_left = 12
			subgroup_style.content_margin_right = 12
			subgroup_style.content_margin_top = 12
			subgroup_style.content_margin_bottom = 12
			subgroup_panel.add_theme_stylebox_override("panel", subgroup_style)
			owner.content.add_child(subgroup_panel)
			var subgroup_list = VBoxContainer.new()
			subgroup_list.add_theme_constant_override("separation", 12)
			subgroup_panel.add_child(subgroup_list)
			var previous_section_container = owner.active_section_container
			owner.active_section_container = subgroup_list
			owner._add_label("زیرگروه‌های " + group_name, 18)
			for category in building_groups[group_name]:
				var category_expanded = owner.selected_building_category == category
				var category_button = owner._add_button(("▼  " if category_expanded else "›  ") + category, owner, "select_building_category", [category])
				category_button.custom_minimum_size.y = 64 if owner.get_viewport_rect().size.x < 900 else 54
				if category_expanded:
					owner._add_building_category_items(category)
			owner.active_section_container = previous_section_container
	if owner.selected_building_category == "معادن":
		owner._add_label("مدیریت معادن:", 18)
		for mine_index in range(game.get_mines().size()):
			var mine = game.get_mines()[mine_index]
			var mine_status = ("فعال" if bool(mine.get("active",false)) else "متوقف")
			if str(mine.get("resource","")) == "iron_ore":
				mine_status += " | ذخیره: %d" % int(mine.get("remaining",0))
				if int(mine.get("remaining",0)) <= 0:
					owner._add_button("شارژ معدن آهن — ۱۰۰۰ سکه", owner, "refill_mine", [mine_index])
			owner._add_label("%s — %s" % [game.get_resource_definitions()[str(mine.get("resource","stone"))].name,mine_status])
	# Show projects immediately after construction starts. Active projects live
	# in state.constructions until completion, not in state.buildings.
	var active_projects = game.get_construction_status()
	if not active_projects.is_empty():
		owner._add_label("🏗️ پروژه‌های در حال ساخت", 18)
		var projects_by_district = {}
		for project_index in range(active_projects.size()):
			var project = active_projects[project_index]
			var project_district = str(project.get("district_name", "منطقه صنعتی خارج شهر"))
			if not projects_by_district.has(project_district):
				projects_by_district[project_district] = []
			projects_by_district[project_district].append(project)
		for project_district in projects_by_district.keys():
			owner._add_label(project_district, 15)
			for project in projects_by_district[project_district]:
				var remaining_seconds = int(project.get("remaining", 0))
				var remaining_minutes = int(ceil(float(remaining_seconds) / 60.0))
				var project_name = str(project.get("name", "ساختمان"))
				var progress_text = "کمتر از یک دقیقه" if remaining_seconds > 0 and remaining_minutes <= 1 else "%d دقیقه" % remaining_minutes
				owner._add_label("🚧 %s — زمان باقی‌مانده: %s" % [project_name, progress_text], 15)
				var speedup_cost = max(1, int(ceil(float(remaining_seconds) / 300.0)))
				var speedup_button = owner._add_button("💎 تکمیل فوری — %d جم" % speedup_cost, owner, "speed_up_construction", [project_index])
				owner._style_button(speedup_button, false)
	owner._add_label("ساختمان‌ها:", 18)
	var district_ids = []
	var district_names = {}
	for building in s.buildings:
		var district_id = str(building.get("district_id", ""))
		var district_name = str(building.get("district_name", "منطقه صنعتی خارج شهر"))
		var group_id = district_id if district_id != "" else "industrial"
		if not district_ids.has(group_id):
			district_ids.append(group_id)
			district_names[group_id] = district_name
	for district_id in district_ids:
		var group_name = str(district_names.get(district_id, "منطقه صنعتی خارج شهر"))
		var expanded = bool(owner.current_district_expanded.get(district_id, false))
		var district_button = owner._add_button(("▼ " if expanded else "▶ ") + group_name, owner, "toggle_current_district", [district_id])
		owner._style_button(district_button, false)
		if expanded:
			var capacity_info = game.get_district_capacity_summary(district_id)
			owner._add_label("ظرفیت محله | خانه‌ها: %d/۲۰  •  ساختمان‌های عادی: %d/۲۰  •  اضطراری: %d/۱۰" % [int(capacity_info.get("house_count",0)),int(capacity_info.get("other_count",0)),int(capacity_info.get("emergency_count",0))], 15)
			owner._add_label("حداکثر ۲ عدد از هر نوع ساختمان؛ سهمیه اضطراری جدا از ظرفیت عادی است.", 14)
			var district_building_counts = {}
			for building in s.buildings:
				var count_district_id = str(building.get("district_id", ""))
				var count_group_id = count_district_id if count_district_id != "" else "industrial"
				if count_group_id != district_id:
					continue
				var count_building_id = str(building.get("id", ""))
				district_building_counts[count_building_id] = int(district_building_counts.get(count_building_id, 0)) + 1
			var district_building_labels = {}
			for i in range(s.buildings.size()):
				var building = s.buildings[i]
				var building_district_id = str(building.get("district_id", ""))
				var building_group_id = building_district_id if building_district_id != "" else "industrial"
				if building_group_id != district_id:
					continue
				var building_id = str(building.get("id", ""))
				var building_definition = game.get_building_definitions().get(building_id, {})
				if not district_building_labels.has(building_id):
					var building_count = int(district_building_counts.get(building_id, 1))
					var building_name = str(building_definition.get("name", "ساختمان"))
					owner._add_label("%s ×%d" % [building_name, building_count], 16)
					district_building_labels[building_id] = true
				var production_output = str(building_definition.get("output", ""))
				if production_output != "":
					var assigned_workers = game._workers_for_building(i)
					var required_workers = int(building_definition.get("jobs", 0))
					var production_amount = int(building_definition.get("amount", 0))
					var production_status = "آماده تولید در نوبت اقتصادی بعدی"
					if assigned_workers <= 0:
						production_status = "متوقف — بدون کارگر"
					elif building_id == "woodcutter" and game.get_forest_tree_count() <= 0:
						production_status = "متوقف — درختی در جنگل باقی نمانده"
					elif str(building_definition.get("input", "")) != "" and int(s.resources.get(str(building_definition.get("input", "")), 0)) < int(building_definition.get("input_amount", 0)):
						production_status = "متوقف — مواد اولیه کافی نیست"
					elif game.get_free_storage() < production_amount:
						production_status = "متوقف — انبار جا ندارد"
					owner._add_label("وضعیت تولید: %s" % production_status, 15)
					owner._add_label("نیروی کار: %d از %d نفر | محصول: %s" % [assigned_workers, required_workers, str(game.get_resource_definitions().get(production_output, {}).get("name", production_output))], 14)
				if int(building.get("balance", 0)) > 0:
					owner._add_label("سود در انتظار انتقال خودکار %s: %d سکه" % [str(building_definition.get("name", "ساختمان")), int(building.get("balance", 0))], 15)
	if district_ids.size() == 0:
		owner._add_label("هنوز ساختمانی در محله‌ای ساخته نشده است.", 15)
