extends RefCounted

# Builds daily, main, and side missions plus city service overview.
static func build(owner, s):
	var game = owner.game
	owner._add_progress_missions_tabs("missions")
	owner._add_label("📅 مأموریت‌های روزانه", 23)
	owner._add_label("هر روز سه هدف تازه برای توسعه شهر؛ پیشرفت و جایزه‌ها جدا از مأموریت‌های اصلی ذخیره می‌شوند.", 16)
	var shown_daily_missions = 0
	for daily_mission in game.get_daily_missions():
		if bool(daily_mission.get("claimed", false)) or shown_daily_missions >= 1:
			continue
		shown_daily_missions += 1
		var daily_card = PanelContainer.new()
		daily_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var daily_style = StyleBoxFlat.new()
		var daily_done = int(daily_mission.progress) >= int(daily_mission.goal)
		daily_style.bg_color = Color("#493719") if daily_done and not bool(daily_mission.claimed) else Color("#202b3b")
		daily_style.border_color = Color("#fbbf24") if daily_done and not bool(daily_mission.claimed) else Color("#64748b")
		daily_style.set_border_width_all(2)
		daily_style.set_corner_radius_all(10)
		daily_style.content_margin_left = 12
		daily_style.content_margin_right = 12
		daily_style.content_margin_top = 10
		daily_style.content_margin_bottom = 10
		daily_card.add_theme_stylebox_override("panel", daily_style)
		owner.content.add_child(daily_card)
		var daily_body = VBoxContainer.new()
		daily_body.add_theme_constant_override("separation", 5)
		daily_card.add_child(daily_body)
		var daily_title = Label.new()
		daily_title.text = owner.PersianText.reshaper(str(daily_mission.title))
		daily_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		daily_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		owner._apply_font(daily_title, 18)
		daily_title.add_theme_color_override("font_color", Color("#fde68a") if daily_done else Color("#ffffff"))
		daily_body.add_child(daily_title)
		var daily_desc = Label.new()
		daily_desc.text = owner.PersianText.reshaper(str(daily_mission.description))
		daily_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		daily_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		owner._apply_font(daily_desc, 16)
		daily_desc.add_theme_color_override("font_color", Color("#dbeafe"))
		daily_body.add_child(daily_desc)
		var daily_progress = Label.new()
		daily_progress.text = owner.PersianText.reshaper("پیشرفت: %d از %d  |  جایزه: %d سکه + %d تجربه" % [int(daily_mission.progress), int(daily_mission.goal), int(daily_mission.reward), int(daily_mission.xp)])
		daily_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		daily_progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		owner._apply_font(daily_progress, 15)
		daily_body.add_child(daily_progress)
		if bool(daily_mission.claimed):
			var daily_status = Label.new()
			daily_status.text = owner.PersianText.reshaper("✓ جایزه امروز دریافت شده")
			daily_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			owner._apply_font(daily_status, 16)
			daily_status.add_theme_color_override("font_color", Color("#86efac"))
			daily_body.add_child(daily_status)
		elif daily_done:
			owner._add_daily_claim_button(daily_body, str(daily_mission.id))
		else:
			var daily_go_button = Button.new()
			daily_go_button.text = owner.PersianText.reshaper("رفتن ←")
			daily_go_button.custom_minimum_size = Vector2(132 if owner.get_viewport_rect().size.x < 900 else 144, 42 if owner.get_viewport_rect().size.x < 900 else 38)
			daily_go_button.size_flags_horizontal = Control.SIZE_SHRINK_END
			owner._apply_font(daily_go_button, 17)
			owner._style_button(daily_go_button, false)
			daily_go_button.connect("pressed", Callable(owner, "go_to_mission_target").bind(str(daily_mission.id)))
			daily_body.add_child(daily_go_button)
			var daily_waiting = Label.new()
			daily_waiting.text = owner.PersianText.reshaper("● در حال انجام")
			daily_waiting.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			owner._apply_font(daily_waiting, 15)
			daily_waiting.add_theme_color_override("font_color", Color("#cbd5e1"))
			daily_body.add_child(daily_waiting)
	owner._add_label("━━━━━━━━━━━━━━━━━━━━", 14)
	var mission_list = game.get_missions()
	var main_total = 0
	var main_claimed = 0
	var side_total = 0
	var side_claimed = 0
	for definition in game.MISSION_DEFINITIONS:
		if bool(definition.get("legacy", false)):
			continue
		if str(definition.get("type","main")) == "side":
			side_total += 1
		else:
			main_total += 1
	for saved_mission in mission_list:
		var saved_type = "main"
		var saved_legacy = false
		for definition in game.MISSION_DEFINITIONS:
			if str(definition.id) == str(saved_mission.get("id","")):
				saved_type = str(definition.get("type","main"))
				saved_legacy = bool(definition.get("legacy", false))
				break
		if bool(saved_mission.get("claimed",false)) and not saved_legacy:
			if saved_type == "side":
				side_claimed += 1
			else:
				main_claimed += 1
	owner._add_label("🎯 مأموریت‌های شهر", 23)
	owner._add_label("اصلی: %d از %d تکمیل‌شده   |   فرعی: %d از %d تکمیل‌شده" % [main_claimed,main_total,side_claimed,side_total],17)
	var summary_panel = PanelContainer.new()
	var summary_style = StyleBoxFlat.new()
	summary_style.bg_color = Color("#172b3f")
	summary_style.border_color = Color("#38bdf8")
	summary_style.set_border_width_all(2)
	summary_style.set_corner_radius_all(12)
	summary_style.content_margin_left = 14
	summary_style.content_margin_right = 14
	summary_style.content_margin_top = 10
	summary_style.content_margin_bottom = 10
	summary_panel.add_theme_stylebox_override("panel", summary_style)
	summary_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	owner.content.add_child(summary_panel)
	var summary_label = Label.new()
	summary_label.text = owner.PersianText.reshaper("پیشرفت کلی مأموریت‌ها: %d از %d" % [main_claimed + side_claimed, main_total + side_total])
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	owner._apply_font(summary_label, 19)
	summary_label.add_theme_color_override("font_color", Color("#ffffff"))
	summary_panel.add_child(summary_label)
	var visible_missions = 0
	var visible_side_missions = 0
	var last_mission_type = ""
	for mission_index in range(mission_list.size()):
		var mission = mission_list[mission_index]
		var definition = {}
		for item in game.MISSION_DEFINITIONS:
			if str(item.id) == str(mission.get("id", "")):
				definition = item
				break
		if definition.is_empty():
			continue
		var is_legacy_mission = bool(definition.get("legacy", false))
		var mission_is_claimed = bool(mission.get("claimed", false))
		var mission_is_unlocked = bool(mission.get("unlocked", false))
		# Claimed missions disappear; future locked missions stay hidden.
		# Only pending legacy rewards remain visible for old save files.
		if is_legacy_mission:
			if mission_is_claimed or not bool(mission.get("completed", false)):
				continue
		elif mission_is_claimed or not mission_is_unlocked:
			continue
		var mission_type = "legacy" if is_legacy_mission else str(definition.get("type","main"))
		# Show only the next available mission in each track, using the
		# same focused card presentation for main and side missions.
		if mission_type == "main" and visible_missions >= 1:
			continue
		if mission_type == "side" and visible_side_missions >= 1:
			continue
		if mission_type == "main":
			visible_missions += 1
		elif mission_type == "side":
			visible_side_missions += 1
		if mission_type != last_mission_type:
			last_mission_type = mission_type
			if mission_type == "legacy":
				owner._add_label("🎁 پاداش‌های باقی‌مانده از نسخه قبلی", 21)
				owner._add_label("اگر در نسخه قبلی مأموریتی را کامل کرده بودی اما جایزه‌اش را نگرفته بودی، اینجا هنوز قابل دریافت است.",15)
			elif mission_type == "main":
				owner._add_label("📘 مأموریت‌های اصلی", 21)
			else:
				owner._add_label("⭐ مأموریت‌های فرعی", 21)
		var is_claimed = bool(mission.get("claimed", false))
		var is_completed = bool(mission.get("completed", false))
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(0, 0)
		card.clip_contents = false
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color("#173b32") if is_claimed else (Color("#493719") if is_completed else Color("#202b3b"))
		card_style.border_color = Color("#4ade80") if is_claimed else (Color("#fbbf24") if is_completed else Color("#64748b"))
		card_style.set_border_width_all(2)
		card_style.set_corner_radius_all(12)
		card_style.content_margin_left = 0
		card_style.content_margin_right = 0
		card_style.content_margin_top = 0
		card_style.content_margin_bottom = 0
		card.add_theme_stylebox_override("panel", card_style)
		owner.content.add_child(card)
		var card_margin = MarginContainer.new()
		card_margin.add_theme_constant_override("offset_left", 14)
		card_margin.add_theme_constant_override("offset_right", 14)
		card_margin.add_theme_constant_override("offset_top", 12)
		card_margin.add_theme_constant_override("offset_bottom", 12)
		card_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(card_margin)
		var card_body = VBoxContainer.new()
		card_body.add_theme_constant_override("separation", 7)
		card_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_body.clip_contents = false
		card_margin.add_child(card_body)
		var is_unlocked = bool(mission.get("unlocked", false))
		var status_text = "✓ جایزه دریافت شده" if is_claimed else ("🎁 جایزه آماده دریافت" if is_completed else ("● در حال انجام" if is_unlocked else "🔒 پس از تکمیل مرحله قبلی باز می‌شود"))
		var title_row = HBoxContainer.new()
		title_row.add_theme_constant_override("separation", 8)
		card_body.add_child(title_row)
		var title_label = Label.new()
		title_label.text = owner.PersianText.reshaper(str(definition.title))
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		title_label.clip_text = false
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_label.custom_minimum_size = Vector2(0, 34)
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		owner._apply_font(title_label, 19)
		title_label.add_theme_color_override("font_color", Color("#86efac") if is_claimed else (Color("#fde68a") if is_completed else Color("#ffffff")))
		title_row.add_child(title_label)
		var status_label = Label.new()
		status_label.text = owner.PersianText.reshaper(status_text)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status_label.clip_text = false
		status_label.custom_minimum_size = Vector2(0, 30)
		status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		owner._apply_font(status_label, 16)
		status_label.add_theme_color_override("font_color", Color("#86efac") if is_claimed else (Color("#fde68a") if is_completed else Color("#cbd5e1")))
		card_body.add_child(status_label)
		var description_label = Label.new()
		description_label.text = owner.PersianText.reshaper(str(definition.description))
		description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.clip_text = false
		description_label.custom_minimum_size = Vector2(0, 48)
		description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		owner._apply_font(description_label, 17)
		description_label.add_theme_color_override("font_color", Color("#f8fafc"))
		card_body.add_child(description_label)
		var current_progress = int(mission.get("progress", 0))
		var target_progress = max(1, int(definition.goal))
		var progress_label = Label.new()
		progress_label.text = owner.PersianText.reshaper("پیشرفت: %d از %d     |     پاداش: %d سکه + %d تجربه" % [current_progress, target_progress, int(definition.reward), int(definition.get("xp",0))])
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		progress_label.clip_text = false
		progress_label.custom_minimum_size = Vector2(0, 34)
		progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		owner._apply_font(progress_label, 16)
		progress_label.add_theme_color_override("font_color", Color("#bae6fd"))
		card_body.add_child(progress_label)
		var mission_progress = ProgressBar.new()
		mission_progress.min_value = 0
		mission_progress.max_value = target_progress
		mission_progress.value = min(current_progress, target_progress)
		mission_progress.show_percentage = false
		mission_progress.custom_minimum_size = Vector2(0, 12)
		var mission_fill = StyleBoxFlat.new()
		mission_fill.bg_color = Color("#22c55e") if is_completed else Color("#38bdf8")
		mission_fill.set_corner_radius_all(6)
		mission_progress.add_theme_stylebox_override("fg", mission_fill)
		var mission_bg = StyleBoxFlat.new()
		mission_bg.bg_color = Color("#334155")
		mission_bg.set_corner_radius_all(6)
		mission_progress.add_theme_stylebox_override("bg", mission_bg)
		card_body.add_child(mission_progress)
		if not is_claimed:
			var hint_label = Label.new()
			hint_label.text = owner.PersianText.reshaper("راهنما: " + str(definition.get("hint", "از بخش‌های شهر هدف را دنبال کن.")))
			hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			hint_label.clip_text = false
			hint_label.custom_minimum_size = Vector2(0, 48)
			hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			owner._apply_font(hint_label, 16)
			hint_label.add_theme_color_override("font_color", Color("#cbd5e1"))
			card_body.add_child(hint_label)
		var go_button = Button.new()
		go_button.text = owner.PersianText.reshaper("رفتن به بخش مربوط  ←")
		go_button.custom_minimum_size = Vector2(148 if owner.get_viewport_rect().size.x < 900 else 160, 44 if owner.get_viewport_rect().size.x < 900 else 40)
		go_button.size_flags_horizontal = Control.SIZE_SHRINK_END
		owner._apply_font(go_button, 17 if owner.get_viewport_rect().size.x < 900 else 16)
		owner._style_button(go_button, false)
		go_button.connect("pressed", Callable(owner, "go_to_mission_target").bind(str(mission.get("id", ""))))
		card_body.add_child(go_button)
		if is_unlocked and is_completed and not is_claimed:
			var claim_button = Button.new()
			claim_button.text = owner.PersianText.reshaper("🎁 دریافت جایزه و باز کردن مرحله بعد")
			claim_button.custom_minimum_size = Vector2(0, 58 if owner.get_viewport_rect().size.x < 900 else 50)
			claim_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			owner._apply_font(claim_button, 18)
			owner._style_button(claim_button, false)
			claim_button.connect("pressed", Callable(owner, "claim_mission").bind(mission_index))
			card_body.add_child(claim_button)
	if visible_missions == 0:
		owner._add_label("آموزش هنوز شروع نشده است؛ بازی را ادامه بده.", 17)
