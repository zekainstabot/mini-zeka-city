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
		var offline_report = owner.game.end_day(true, false)
		var digest = str(offline_report).split("\n")
		for digest_line in digest:
			var clean_line = str(digest_line).strip_edges()
			clean_line = clean_line.replace("نویدشهر", "یکی از شهرهای رقیب")
			if clean_line != "" and (clean_line.find("رویداد") >= 0 or clean_line.find("تصمیم") >= 0 or clean_line.find("رقبا") >= 0 or clean_line.find("درخواست") >= 0 or clean_line.find("تبریک") >= 0 or clean_line.find("تولید") >= 0):
				owner.game.state["pending_offline_digest"].append(clean_line)
		# Yield between simulated days so the loading screen can keep rendering.
		var progress_value = 63 + int(round(float(day_index + 1) / float(max(1, offline_days)) * 10.0))
		owner._set_startup_progress(progress_value, "شبیه‌سازی روزهای گذشته: %d از %d" % [day_index + 1, offline_days])
		await owner.get_tree().process_frame
	# Always yield once, including a first launch with no offline days, so the
	# startup coroutine completes predictably in headless and mobile runtimes.
	if offline_days <= 0:
		await owner.get_tree().process_frame
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
	var safe_area = owner._get_safe_area_insets()
	var compact = viewport_size.x < 700.0
	var popup_width = min(500.0, viewport_size.x - safe_area.x - safe_area.z - 32.0)
	var popup_height = max(180.0, min(560.0, viewport_size.y - safe_area.y - safe_area.w - 32.0))

	# Remove duplicate/empty report lines and show only the three most useful items.
	var digest_items = owner.game.state.get("pending_offline_digest", [])
	var unique_digest_items: Array = []
	var seen_digest_items: Dictionary = {}
	for item in digest_items:
		var line = str(item).strip_edges()
		if line.is_empty() or seen_digest_items.has(line):
			continue
		seen_digest_items[line] = true
		unique_digest_items.append(line)

	var overlay = Control.new()
	overlay.name = "WelcomeBackOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	owner.offline_summary_popup = overlay

	var shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.035, 0.055, 0.86)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = safe_area.x + 16.0
	center.offset_right = -(safe_area.z + 16.0)
	center.offset_top = safe_area.y + 16.0
	center.offset_bottom = -(safe_area.w + 16.0)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(popup_width, popup_height)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color("#102438")
	card_style.border_color = Color("#31566a")
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(24)
	card_style.content_margin_left = 18 if compact else 26
	card_style.content_margin_right = 18 if compact else 26
	card_style.content_margin_top = 20 if compact else 26
	card_style.content_margin_bottom = 18 if compact else 24
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var scroll = ScrollContainer.new()
	scroll.name = "WelcomeBackScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(scroll)
	var layout = VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 12 if compact else 15)
	scroll.add_child(layout)

	var icon_wrap = CenterContainer.new()
	layout.add_child(icon_wrap)
	var icon_circle = PanelContainer.new()
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = Color("#1d4c50")
	icon_style.set_corner_radius_all(40)
	icon_style.content_margin_left = 13
	icon_style.content_margin_right = 13
	icon_style.content_margin_top = 9
	icon_style.content_margin_bottom = 9
	icon_circle.add_theme_stylebox_override("panel", icon_style)
	icon_wrap.add_child(icon_circle)
	var icon_label = Label.new()
	icon_label.text = "⌂"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owner._apply_font(icon_label, 31)
	icon_label.add_theme_color_override("font_color", Color("#8ee4c8"))
	icon_circle.add_child(icon_label)

	var heading = Label.new()
	heading.text = owner.PersianText.reshaper("خوش برگشتی! 👋")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(heading, 23 if compact else 27)
	heading.add_theme_color_override("font_color", Color("#fff8e8"))
	layout.add_child(heading)

	var city_name = str(owner.game.state.get("city_name", "شهرت")).strip_edges()
	var intro = Label.new()
	intro.text = owner.PersianText.reshaper("دلمون برای شهرت تنگ شده بود!\nدر این مدت، %s منتظر برگشتت بود." % city_name)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(intro, 13 if compact else 15)
	intro.add_theme_color_override("font_color", Color("#b9cbd5"))
	layout.add_child(intro)

	var stats = HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	layout.add_child(stats)

	var days_card = PanelContainer.new()
	days_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var days_style = StyleBoxFlat.new()
	days_style.bg_color = Color("#1c3c57")
	days_style.set_corner_radius_all(15)
	days_style.content_margin_top = 12
	days_style.content_margin_bottom = 12
	days_style.content_margin_left = 6
	days_style.content_margin_right = 6
	days_card.add_theme_stylebox_override("panel", days_style)
	stats.add_child(days_card)
	var days_content = VBoxContainer.new()
	days_content.add_theme_constant_override("separation", 3)
	days_card.add_child(days_content)
	var days_value = Label.new()
	days_value.text = owner.PersianText.reshaper("%d" % days)
	days_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owner._apply_font(days_value, 25 if compact else 29)
	days_value.add_theme_color_override("font_color", Color("#ffffff"))
	days_content.add_child(days_value)
	var days_caption = Label.new()
	days_caption.text = owner.PersianText.reshaper("روز دوری از شهر")
	days_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	days_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	days_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	owner._apply_font(days_caption, 11 if compact else 13)
	days_caption.add_theme_color_override("font_color", Color("#b9d8eb"))
	days_content.add_child(days_caption)

	var income_card = PanelContainer.new()
	income_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var income_style = StyleBoxFlat.new()
	income_style.bg_color = Color("#17483e") if income > 0 else Color("#263747")
	income_style.set_corner_radius_all(15)
	income_style.content_margin_top = 12
	income_style.content_margin_bottom = 12
	income_style.content_margin_left = 6
	income_style.content_margin_right = 6
	income_card.add_theme_stylebox_override("panel", income_style)
	stats.add_child(income_card)
	var income_content = VBoxContainer.new()
	income_content.add_theme_constant_override("separation", 3)
	income_card.add_child(income_content)
	var income_value = Label.new()
	income_value.text = owner.PersianText.reshaper("%s" % str(income))
	income_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owner._apply_font(income_value, 25 if compact else 29)
	income_value.add_theme_color_override("font_color", Color("#9af0c0") if income > 0 else Color("#e2e8f0"))
	income_content.add_child(income_value)
	var income_caption = Label.new()
	income_caption.text = owner.PersianText.reshaper("سکه درآمد آماده دریافت")
	income_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	income_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	income_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	owner._apply_font(income_caption, 11 if compact else 13)
	income_caption.add_theme_color_override("font_color", Color("#b9d8c9"))
	income_content.add_child(income_caption)

	var news_title = Label.new()
	news_title.text = owner.PersianText.reshaper("📰  خبرهای شهر")
	news_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner._apply_font(news_title, 14 if compact else 16)
	news_title.add_theme_color_override("font_color", Color("#f2c879"))
	layout.add_child(news_title)

	var news_panel = PanelContainer.new()
	var news_style = StyleBoxFlat.new()
	news_style.bg_color = Color("#172f43")
	news_style.set_corner_radius_all(14)
	news_style.content_margin_left = 12
	news_style.content_margin_right = 12
	news_style.content_margin_top = 10
	news_style.content_margin_bottom = 10
	news_panel.add_theme_stylebox_override("panel", news_style)
	layout.add_child(news_panel)

	var news_list = VBoxContainer.new()
	news_list.add_theme_constant_override("separation", 8)
	news_panel.add_child(news_list)
	if unique_digest_items.is_empty():
		var calm = Label.new()
		calm.text = owner.PersianText.reshaper("همه‌چیز آروم بوده؛ شهر به سلامت منتظرت مونده 😊")
		calm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		calm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		owner._apply_font(calm, 12 if compact else 14)
		calm.add_theme_color_override("font_color", Color("#c6d8df"))
		news_list.add_child(calm)
	else:
		for index in range(min(unique_digest_items.size(), 3)):
			var event_label = Label.new()
			var event_text = str(unique_digest_items[index]).replace("نویدشهر", "یکی از شهرهای رقیب")
			event_label.text = owner.PersianText.reshaper("•  " + event_text)
			event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			event_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			owner._apply_font(event_label, 12 if compact else 14)
			event_label.add_theme_color_override("font_color", Color("#e1edf0"))
			news_list.add_child(event_label)

	var action_button = Button.new()
	if income > 0:
		action_button.text = owner.PersianText.reshaper("دریافت %s سکه و ورود به شهر" % str(income))
		action_button.pressed.connect(Callable(owner, "_claim_offline_income"))
	else:
		action_button.text = owner.PersianText.reshaper("بزن بریم، ورود به شهر")
		action_button.pressed.connect(Callable(owner, "_close_offline_summary"))
	action_button.custom_minimum_size = Vector2(0, 52 if compact else 56)
	action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	owner._apply_font(action_button, 14 if compact else 16)
	owner._style_button(action_button, true)
	layout.add_child(action_button)

	var reassurance = Label.new()
	reassurance.text = owner.PersianText.reshaper("هر وقت آماده‌ای، ادامه بده.")
	reassurance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owner._apply_font(reassurance, 10 if compact else 11)
	reassurance.add_theme_color_override("font_color", Color("#819aa8"))
	layout.add_child(reassurance)

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
