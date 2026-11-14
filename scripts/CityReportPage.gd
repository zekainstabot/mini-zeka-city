extends RefCounted

# Builds the city event and resident report page.
static func build(owner, s):
	owner._add_label("گزارش وقایع شهر", 22)
	var events = s.get("report_events", [])
	owner._add_label("گزارش‌های مردم و اتفاقات شهر | تعداد فعلی: %d" % events.size(), 15)
	if events.is_empty():
		owner._add_label("گزارشی برای نمایش وجود ندارد.", 18)
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
				owner._add_button("🏗️ رفتن به ساختمانِ حل‌کننده مشکل", owner, "go_to_report_solution", [issue_key, service_need])
