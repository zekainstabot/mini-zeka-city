extends RefCounted

# Builds the city event and resident report page.
static func build(owner, s):
	owner._add_label("گزارش وقایع شهر", 22)
	var all_events = s.get("report_events", [])
	var filters = [
		{"id":"all","label":"همه"},
		{"id":"citizens","label":"شهروندان"},
		{"id":"issues","label":"مشکلات"},
		{"id":"finance","label":"مالی"},
		{"id":"trade","label":"تجارت"},
		{"id":"progress","label":"پیشرفت"},
		{"id":"events","label":"رویدادها"}
	]
	var filter_row = HFlowContainer.new()
	filter_row.name = "ReportCategoryFilters"
	filter_row.add_theme_constant_override("h_separation", 6)
	filter_row.add_theme_constant_override("v_separation", 6)
	owner.content.add_child(filter_row)
	for filter_data in filters:
		var filter_button = Button.new()
		filter_button.name = "ReportFilter_" + str(filter_data.id)
		filter_button.text = owner.PersianText.reshaper(str(filter_data.label))
		filter_button.custom_minimum_size = Vector2(88, 42)
		owner._apply_font(filter_button, 14)
		owner._style_button(filter_button, str(owner.report_filter_category) == str(filter_data.id))
		filter_button.pressed.connect(Callable(owner, "_set_report_filter").bind(str(filter_data.id)))
		filter_row.add_child(filter_button)
	var events = []
	for candidate in all_events:
		var category = str(candidate.get("category", ""))
		if category.is_empty():
			category = owner.game.get_report_event_category(candidate.get("message", ""))
		if str(owner.report_filter_category) == "all" or category == str(owner.report_filter_category):
			events.append(candidate)
	owner._add_label("گزارش‌های مهم شهر | نمایش %d از %d" % [events.size(), all_events.size()], 15)
	if events.is_empty():
		owner._add_label("در این دسته گزارشی برای نمایش وجود ندارد.", 18)
	else:
		for event_index in range(events.size() - 1, -1, -1):
			var event = events[event_index]
			var stamp = Time.get_datetime_dict_from_unix_time(int(event.get("timestamp", 0)))
			var time_text = "%02d/%02d - %02d:%02d" % [int(stamp.get("day", 1)), int(stamp.get("month", 1)), int(stamp.get("hour", 0)), int(stamp.get("minute", 0))]
			var status_text = " | مشکل برطرف شده" if bool(event.get("resolved", false)) else ""
			owner._add_label("[%s] روز %d | %s%s" % [time_text, int(event.get("day", 1)), str(event.get("message", "")), status_text], 17)
			# Only citizen complaints get a solution shortcut; ordinary city logs stay informational.
			var is_citizen_complaint = int(event.get("citizen_id", 0)) > 0 or str(event.get("district_id", "")) != ""
			if is_citizen_complaint:
				var issue_key = str(event.get("issue_key", ""))
				var service_need = str(event.get("service_need", ""))
				owner._add_button("🏗️ رفع مشکل", owner, "go_to_report_solution", [issue_key, service_need])
