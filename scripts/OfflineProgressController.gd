extends RefCounted

# Offline simulation, welcome-back summary, and deferred income collection.

static func _apply_offline_progress(owner):
	# Keep offline digest keys initialized even when no full offline day elapsed.
	owner.game.state["pending_offline_digest"] = owner.game.state.get("pending_offline_digest", [])
	var now = Time.get_unix_time_from_system()
	var last = int(owner.game.state.get("clock_last_unix", now))
	var elapsed = max(0, now - last)
	# One in-game day of offline simulation equals one real hour.
	var elapsed_offline_days = int(floor(float(elapsed) / 3600.0))
	# Simulate at most ten days per return to keep catch-up processing bounded.
	var offline_days = min(10, elapsed_offline_days)
	var money_before = int(owner.game.state.get("money", 0))
	if offline_days > 0:
		owner.game.state["pending_offline_digest"] = []
	for day_index in range(offline_days):
		var offline_report = owner.game.end_day(true)
		var digest = str(offline_report).split("\n")
		for digest_line in digest:
			var clean_line = str(digest_line).strip_edges()
			clean_line = clean_line.replace("نویدشهر", "یکی از شهرهای رقیب")
			if clean_line != "" and (clean_line.find("رویداد") >= 0 or clean_line.find("تصمیم") >= 0 or clean_line.find("رقبا") >= 0 or clean_line.find("درخواست") >= 0 or clean_line.find("تبریک") >= 0 or clean_line.find("تولید") >= 0):
				owner.game.state["pending_offline_digest"].append(clean_line)
	while owner.game.state["pending_offline_digest"].size() > 8:
		owner.game.state["pending_offline_digest"].pop_front()
	var offline_net = int(owner.game.state.get("money", money_before)) - money_before
	# Positive net earnings are held separately until the player explicitly collects them.
	if offline_net > 0:
		owner.game.state["money"] = money_before
		owner.game.state["pending_offline_income"] = int(owner.game.state.get("pending_offline_income", 0)) + offline_net
	if elapsed_offline_days > 0:
		owner.game.state["pending_offline_days"] = int(owner.game.state.get("pending_offline_days", 0)) + elapsed_offline_days
	# Only request the welcome-back dialog after a single absence longer than
	# ten in-game days. Short visits/returns never trigger it.
	if elapsed_offline_days > 10:
		owner.game.state["pending_offline_summary_ready"] = true
	owner.game.state["clock_last_unix"] = now
	owner.game.state["clock_cycle_seconds"] = int(owner.game.state.get("clock_cycle_seconds", 0))
	owner.game.save_game()

static func _show_offline_summary(owner):
	var days = int(owner.game.state.get("pending_offline_days", 0))
	if days <= 0 or not bool(owner.game.state.get("pending_offline_summary_ready", false)):
		return
	owner.game.state["pending_offline_summary_ready"] = false
	owner.game.save_game()

	var income = int(owner.game.state.get("pending_offline_income", 0))
	var viewport_size = owner.get_viewport_rect().size
	var compact = viewport_size.x < 700.0
	var popup_width = min(520.0, viewport_size.x - 28.0)

	# Keep only distinct, useful events from the offline report.
	var digest_items = owner.game.state.get("pending_offline_digest", [])
	var unique_digest_items: Array = []
	var seen_digest_items: Dictionary = {}
	for item in digest_items:
		var line = str(item).strip_edges()
		if line.is_empty() or seen_digest_items.has(line):
			continue
		seen_digest_items[line] = true
		unique_digest_items.append(line)

	# A lightweight in-game sheet replaces the fragile PopupPanel sizing.
	var overlay = Control.new()
	overlay.name = "WelcomeBackOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	owner.offline_summary_popup = overlay
	var shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.055, 0.09, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 14
	center.offset_right = -14
	center.offset_top = 14
	center.offset_bottom = -14
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(popup_width, 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color("#14243a")
	card_style.border_color = Color("#3b647e")
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(20)
	card_style.content_margin_left = 16 if compact else 24
	card_style.content_margin_right = 16 if compact else 24
	card_style.content_margin_top = 16 if compact else 22
	card_style.content_margin_bottom = 16 if compact else 22
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10 if compact else 13)
	card.add_child(layout)

	var heading = Label.new()
	heading.text = owner.PersianText.reshaper("خوش برگشتی به %s! 👋" % str(owner.game.state.get("city_name", "شهرت")))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(heading, 21 if compact else 25)
	heading.add_theme_color_override("font_color", Color("#ffffff"))
	layout.add_child(heading)

	var intro = Label.new()
	intro.text = owner.PersianText.reshaper("این مدت شهر تنها نبوده؛ ببین در غیابت چه خبر بوده.")
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(intro, 12 if compact else 14)
	intro.add_theme_color_override("font_color", Color("#cbd5e1"))
	layout.add_child(intro)

	var stats = HBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	layout.add_child(stats)
	var days_card = PanelContainer.new()
	days_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var days_style = StyleBoxFlat.new()
	days_style.bg_color = Color("#203f62")
	days_style.set_corner_radius_all(12)
	days_style.content_margin_top = 10
	days_style.content_margin_bottom = 10
	days_style.content_margin_left = 6
	days_style.content_margin_right = 6
	days_card.add_theme_stylebox_override("panel", days_style)
	stats.add_child(days_card)
	var days_label = Label.new()
	days_label.text = owner.PersianText.reshaper("%d روز دور از شهر" % days)
	days_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	days_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(days_label, 14 if compact else 17)
	days_label.add_theme_color_override("font_color", Color("#dbeafe"))
	days_card.add_child(days_label)

	var income_card = PanelContainer.new()
	income_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var income_style = StyleBoxFlat.new()
	income_style.bg_color = Color("#174b3d") if income > 0 else Color("#29384b")
	income_style.set_corner_radius_all(12)
	income_style.content_margin_top = 10
	income_style.content_margin_bottom = 10
	income_style.content_margin_left = 6
	income_style.content_margin_right = 6
	income_card.add_theme_stylebox_override("panel", income_style)
	stats.add_child(income_card)
	var income_label = Label.new()
	income_label.text = owner.PersianText.reshaper("%s سکه درآمد" % str(income))
	income_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	income_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(income_label, 14 if compact else 17)
	income_label.add_theme_color_override("font_color", Color("#86efac") if income > 0 else Color("#e2e8f0"))
	income_card.add_child(income_label)

	var news_title = Label.new()
	news_title.text = owner.PersianText.reshaper("📌 اتفاقات مهم شهر")
	news_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner._apply_font(news_title, 15 if compact else 17)
	news_title.add_theme_color_override("font_color", Color("#fbbf24"))
	layout.add_child(news_title)

	var news_scroll = ScrollContainer.new()
	news_scroll.custom_minimum_size = Vector2(0, min(112.0, max(42.0, float(min(unique_digest_items.size(), 3)) * 36.0)))
	news_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	news_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	news_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(news_scroll)
	var news_list = VBoxContainer.new()
	news_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	news_list.add_theme_constant_override("separation", 6)
	news_scroll.add_child(news_list)
	if unique_digest_items.is_empty():
		var calm = Label.new()
		calm.text = owner.PersianText.reshaper("اتفاق ویژه‌ای ثبت نشده؛ شهر آرام بوده است.")
		calm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		calm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		owner._apply_font(calm, 12 if compact else 14)
		calm.add_theme_color_override("font_color", Color("#cbd5e1"))
		news_list.add_child(calm)
	else:
		for index in range(min(unique_digest_items.size(), 8)):
			var event_label = Label.new()
			var event_text = str(unique_digest_items[index]).replace("نویدشهر", "یکی از شهرهای رقیب")
			event_label.text = owner.PersianText.reshaper("• " + event_text)
			event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			event_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			owner._apply_font(event_label, 12 if compact else 14)
			event_label.add_theme_color_override("font_color", Color("#e2e8f0"))
			news_list.add_child(event_label)

	if income > 0:
		var claim = Button.new()
		claim.text = owner.PersianText.reshaper("واریز %s سکه به خزانه" % str(income))
		claim.custom_minimum_size = Vector2(0, 48 if compact else 52)
		claim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		owner._apply_font(claim, 14 if compact else 16)
		owner._style_button(claim, false)
		claim.pressed.connect(_claim_offline_income)
		layout.add_child(claim)

	var continue_button = Button.new()
	continue_button.text = owner.PersianText.reshaper("ادامه بازی")
	continue_button.custom_minimum_size = Vector2(0, 44 if compact else 48)
	continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	owner._apply_font(continue_button, 14 if compact else 16)
	owner._style_button(continue_button, true)
	continue_button.pressed.connect(_close_offline_summary)
	layout.add_child(continue_button)

	owner.add_child(overlay)

static func _close_offline_summary(owner):
	if owner.offline_summary_popup != null and is_instance_valid(owner.offline_summary_popup):
		owner.offline_summary_popup.queue_free()
	owner.offline_summary_popup = null
	owner.show_page("home")

static func _claim_offline_income(owner):
	if owner.offline_summary_popup != null and is_instance_valid(owner.offline_summary_popup):
		owner.offline_summary_popup.queue_free()
	owner.offline_summary_popup = null
	var result = owner.game.collect_offline_income()
	var message = str(result.get("message", "درآمد به خزانه واریز شد."))
	if int(owner.game.state.get("pending_offline_income", 0)) <= 0:
		owner.game.state["pending_offline_days"] = 0
		owner.game.state["pending_offline_summary_ready"] = false
		owner.game.save_game()
	owner.show_page("home")
	owner._show_message(message)
