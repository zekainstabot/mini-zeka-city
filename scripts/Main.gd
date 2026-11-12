extends Control

const EngineScript = preload("res://scripts/GameEngine.gd")
const PersianText = preload("res://scripts/PersianText.gd")
var game = null
var current_page = "home"
var message_label = null
var content = null
var header_label = null
var ui_font = null
var level_status_bar = null
var xp_progress_bar = null
var level_status_label = null
var xp_progress_label = null
var selected_home_building_id = ""
var selected_building_category = ""
var selected_demolish_quantity = 1
var demolish_panel_expanded = false
var home_buildings_expanded = false
var home_city_details_expanded = false
var home_economy_expanded = false
var clock_cycle_seconds = 0.0
var clock_label = null
var clock_save_accumulator = 0.0
var construction_check_accumulator = 0.0
var construction_time_labels = []
var game_paused = false
var menu_panel = null
var menu_pause_button = null
var game_scroll_container = null
var touch_scroll_active = false
var touch_scroll_start = Vector2()
var touch_scroll_last_y = 0.0
var touch_scroll_last_position = Vector2()
var touch_scroll_dragging = false
var touch_scroll_axis = ""
var horizontal_scroll_velocity = 0.0
var restart_confirm_panel = null
var municipality_section_expanded = {"land":false,"tax":false,"requests":false,"properties":false,"projects":false}
var citizen_status_expanded = {}
var commerce_section_expanded = {"domestic":false,"export":false,"import":false,"shipments":false,"contracts":false}
var storage_section_expanded = {}
var current_district_expanded = {}
var active_section_container = null
var mission_reward_badge = null
var mission_badge_refresh_timer = 0.0
var last_activity_ticks = 0
var offline_summary_popup = null

func _input(event):
	if game != null:
		var meaningful_input = false
		if event is InputEventScreenTouch and event.pressed:
			meaningful_input = true
		elif event is InputEventMouseButton and event.pressed:
			meaningful_input = true
		elif event is InputEventKey and event.pressed and not event.echo:
			meaningful_input = true
		if meaningful_input:
			last_activity_ticks = OS.get_ticks_msec()
	if game_scroll_container == null or not is_instance_valid(game_scroll_container):
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_scroll_active = game_scroll_container.get_global_rect().has_point(event.position)
			touch_scroll_start = event.position
			touch_scroll_last_y = event.position.y
			touch_scroll_last_position = event.position
			touch_scroll_axis = ""
			touch_scroll_dragging = false
		else:
			touch_scroll_active = false
			touch_scroll_dragging = false
			touch_scroll_axis = ""
	elif event is InputEventScreenDrag and touch_scroll_active:
		var moved = event.position - touch_scroll_start
		if not touch_scroll_dragging and moved.length() > 9.0:
			touch_scroll_dragging = true
			if abs(moved.x) > abs(moved.y) * 1.15:
				touch_scroll_axis = "horizontal"
			else:
				touch_scroll_axis = "vertical"
		if touch_scroll_dragging:
			var delta_position = event.position - touch_scroll_last_position
			if touch_scroll_axis == "horizontal":
				var horizontal_bar = game_scroll_container.get_h_scrollbar()
				var max_horizontal = max(0.0, horizontal_bar.max_value - horizontal_bar.page)
				game_scroll_container.scroll_horizontal = int(clamp(float(game_scroll_container.scroll_horizontal) - delta_position.x * 1.25, 0.0, max_horizontal))
				horizontal_scroll_velocity = -delta_position.x * 13.0
			elif touch_scroll_axis == "vertical":
				var delta_y = event.position.y - touch_scroll_last_y
				var bar = game_scroll_container.get_v_scrollbar()
				var max_scroll = max(0.0, bar.max_value - bar.page)
				game_scroll_container.scroll_vertical = int(clamp(float(game_scroll_container.scroll_vertical) - delta_y * 1.35, 0.0, max_scroll))
		touch_scroll_last_y = event.position.y
		touch_scroll_last_position = event.position

func _process(delta):
	if not touch_scroll_dragging and abs(horizontal_scroll_velocity) > 8.0 and game_scroll_container != null and is_instance_valid(game_scroll_container):
		var horizontal_bar = game_scroll_container.get_h_scrollbar()
		var max_horizontal = max(0.0, horizontal_bar.max_value - horizontal_bar.page)
		game_scroll_container.scroll_horizontal = int(clamp(float(game_scroll_container.scroll_horizontal) + horizontal_scroll_velocity * delta, 0.0, max_horizontal))
		horizontal_scroll_velocity = lerp(horizontal_scroll_velocity, 0.0, min(1.0, delta * 7.5))
	else:
		horizontal_scroll_velocity = 0.0
	if game == null or game_paused:
		return
	if last_activity_ticks > 0 and OS.get_ticks_msec() - last_activity_ticks <= 90000:
		game.record_active_play_seconds(delta)
	clock_cycle_seconds += delta
	mission_badge_refresh_timer += delta
	if mission_badge_refresh_timer >= 1.0:
		mission_badge_refresh_timer = 0.0
		_update_mission_reward_badge()
	clock_save_accumulator += delta
	construction_check_accumulator += delta
	if construction_check_accumulator >= 1.0:
		construction_check_accumulator = 0.0
		_update_construction_time_labels()
		if game.process_constructions():
			show_page(current_page)
			_show_message(str(game.state.get("last_report", "ساخت‌وساز تکمیل شد.")))
	if clock_cycle_seconds >= 600.0:
		clock_cycle_seconds -= 600.0
		game.end_day()
		game.state["clock_last_unix"] = OS.get_unix_time()
		game.state["clock_cycle_seconds"] = int(clock_cycle_seconds)
		game.save_game()
		if current_page == "home":
			show_page("home")
			_show_message("یک روز جدید در شهر آغاز شد.")
	if clock_label != null and is_instance_valid(clock_label):
		var remaining = max(0, int(600.0 - clock_cycle_seconds))
		var phase = "روز" if clock_cycle_seconds < 420.0 else "شب"
		var phase_remaining = int(420.0 - clock_cycle_seconds) if phase == "روز" else int(600.0 - clock_cycle_seconds)
		clock_label.text = PersianText.reshaper("%s | زمان باقی‌مانده: " % phase) + _format_time_display(int(phase_remaining / 60), phase_remaining % 60)
	if clock_save_accumulator >= 15.0:
		clock_save_accumulator = 0.0
		game.state["clock_last_unix"] = OS.get_unix_time()
		game.state["clock_cycle_seconds"] = int(clock_cycle_seconds)
		game.save_game()

func _format_time_display(minutes, seconds):
	# Keep the numeric timer in left-to-right order; PersianText.reshaper reverses digit groups.
	return "\u200E%02d:%02d\u200E" % [int(minutes), int(seconds)]

func _update_construction_time_labels():
	if construction_time_labels.size() == 0 or game == null:
		return
	var active = game.get_construction_status()
	var count = min(active.size(), construction_time_labels.size())
	for i in range(count):
		var project = active[i]
		var seconds_left = int(project.remaining)
		var label = construction_time_labels[i].get("label", null)
		if label != null and is_instance_valid(label):
			label.text = PersianText.reshaper("%s | زمان باقی‌مانده: " % str(project.name)) + _format_time_display(int(seconds_left / 60), seconds_left % 60)

func _apply_offline_progress():
	var now = OS.get_unix_time()
	var last = int(game.state.get("clock_last_unix", now))
	var elapsed = max(0, now - last)
	var offline_days = min(10, int(floor(float(elapsed) / 3600.0)))
	var money_before = int(game.state.get("money", 0))
	if offline_days > 0:
		game.state["pending_offline_digest"] = []
	for day_index in range(offline_days):
		var offline_report = game.end_day(true)
		var digest = str(offline_report).split("\n")
		for digest_line in digest:
			var clean_line = str(digest_line).strip_edges()
			if clean_line != "" and (clean_line.find("رویداد") >= 0 or clean_line.find("تصمیم") >= 0 or clean_line.find("رقبا") >= 0 or clean_line.find("درخواست") >= 0 or clean_line.find("تبریک") >= 0 or clean_line.find("تولید") >= 0):
				game.state.pending_offline_digest.append(clean_line)
	while game.state.pending_offline_digest.size() > 8:
		game.state.pending_offline_digest.pop_front()
	var offline_net = int(game.state.get("money", money_before)) - money_before
	# Positive net earnings are held separately until the player explicitly collects them.
	if offline_net > 0:
		game.state["money"] = money_before
		game.state["pending_offline_income"] = int(game.state.get("pending_offline_income", 0)) + offline_net
	if offline_days > 0:
		game.state["pending_offline_days"] = int(game.state.get("pending_offline_days", 0)) + offline_days
	game.state["clock_last_unix"] = now
	game.state["clock_cycle_seconds"] = int(game.state.get("clock_cycle_seconds", 0))
	game.save_game()

func _show_offline_summary():
	var days = int(game.state.get("pending_offline_days", 0))
	if days <= 0:
		return
	var income = int(game.state.get("pending_offline_income", 0))
	var compact = get_viewport_rect().size.x < 900
	var popup = PopupPanel.new()
	offline_summary_popup = popup
	popup.name = "OfflineIncomePopup"
	var card = PanelContainer.new()
	card.rect_min_size = Vector2(300 if compact else 440, 0)
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color("#172235")
	card_style.border_color = Color("#64748b")
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(14)
	card_style.content_margin_left = 18
	card_style.content_margin_right = 18
	card_style.content_margin_top = 18
	card_style.content_margin_bottom = 18
	card.add_stylebox_override("panel", card_style)
	popup.add_child(card)
	var layout = VBoxContainer.new()
	layout.add_constant_override("separation", 12)
	card.add_child(layout)

	var title = Label.new()
	title.text = PersianText.reshaper("گزارش بازگشت به شهر")
	title.align = Label.ALIGN_CENTER
	title.autowrap = true
	_apply_font(title, 23 if compact else 21)
	title.add_color_override("font_color", Color("#ffffff"))
	layout.add_child(title)

	var details = Label.new()
	details.align = Label.ALIGN_CENTER
	details.autowrap = true
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.rect_min_size = Vector2(0, 86 if compact else 76)
	if income > 0:
		details.text = PersianText.reshaper("در زمان نبودنت، شهر %d روز فعالیت کرده است.\nدرآمد خالص قابل دریافت:" % days)
	else:
		details.text = PersianText.reshaper("در زمان نبودنت، شهر %d روز فعالیت کرده است.\nدرآمد و هزینه‌ها محاسبه شدند، اما درآمد خالصی برای دریافت باقی نمانده است." % days)
	_apply_font(details, 18 if compact else 17)
	details.add_color_override("font_color", Color("#e2e8f0"))
	layout.add_child(details)


	var digest_items = game.state.get("pending_offline_digest", [])
	if not digest_items.empty():
		var news_title = Label.new()
		news_title.text = PersianText.reshaper("📰 خبرهای مهم در زمان غیبت")
		news_title.align = Label.ALIGN_CENTER
		_apply_font(news_title, 18 if compact else 17)
		news_title.add_color_override("font_color", Color("#fbbf24"))
		layout.add_child(news_title)
		var shown_news = 0
		for news_item in digest_items:
			if shown_news >= 5:
				break
			var news_label = Label.new()
			news_label.text = PersianText.reshaper("• " + str(news_item))
			news_label.align = Label.ALIGN_RIGHT
			news_label.autowrap = true
			news_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_apply_font(news_label, 15 if compact else 14)
			news_label.add_color_override("font_color", Color("#dbeafe"))
			layout.add_child(news_label)
			shown_news += 1

	if income > 0:
		var amount = Label.new()
		amount.text = PersianText.reshaper("%d سکه" % income)
		amount.align = Label.ALIGN_CENTER
		amount.autowrap = true
		amount.rect_min_size = Vector2(0, 44)
		_apply_font(amount, 26 if compact else 24)
		amount.add_color_override("font_color", Color("#86efac"))
		layout.add_child(amount)

		var claim_button = Button.new()
		claim_button.text = PersianText.reshaper("دریافت درآمد در خزانه")
		claim_button.rect_min_size = Vector2(0, 58 if compact else 52)
		claim_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_font(claim_button, 19 if compact else 17)
		_style_button(claim_button, false)
		claim_button.connect("pressed", self, "_claim_offline_income")
		layout.add_child(claim_button)

	var later_button = Button.new()
	later_button.text = PersianText.reshaper("بعداً")
	later_button.rect_min_size = Vector2(0, 54 if compact else 48)
	later_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(later_button, 18 if compact else 16)
	_style_button(later_button, true)
	later_button.connect("pressed", popup, "hide")
	layout.add_child(later_button)

	add_child(popup)
	popup.popup_centered(Vector2(380 if compact else 520, 470 if compact else 420))

func _claim_offline_income():
	if offline_summary_popup != null and is_instance_valid(offline_summary_popup):
		offline_summary_popup.queue_free()
	offline_summary_popup = null
	var pending = int(game.state.get("pending_offline_income", 0))
	var message = "گزارش آفلاین بسته شد."
	if pending > 0:
		var result = game.collect_offline_income()
		message = str(result.message)
	if int(game.state.get("pending_offline_income", 0)) <= 0:
		game.state["pending_offline_days"] = 0
		game.save_game()
	show_page("home")
	_show_message(message)

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST and game != null:
		game.state["clock_last_unix"] = OS.get_unix_time()
		game.state["clock_cycle_seconds"] = int(clock_cycle_seconds)
		game.save_game()

func _ready():
	_load_ui_font()
	game = EngineScript.new()
	if not game.load_game():
		game.new_game()
		game.save_game()
	game.register_login_today()
	game.get_daily_missions()
	game.get_weekly_challenge()
	last_activity_ticks = OS.get_ticks_msec()
	_apply_offline_progress()
	clock_cycle_seconds = float(game.state.get("clock_cycle_seconds", 0))
	set_process(true)
	_build_ui()
	show_page("home")
	_show_offline_summary()

func _build_ui():
	var background = ColorRect.new()
	background.color = Color("#101827")
	background.anchor_right = 1
	background.anchor_bottom = 1
	add_child(background)
	var root = VBoxContainer.new()
	root.anchor_right = 1
	root.anchor_bottom = 1
	var screen_width = get_viewport_rect().size.x
	var compact_layout = screen_width < 900
	root.margin_left = 28 if compact_layout else 24
	root.margin_top = 16 if compact_layout else 22
	root.margin_right = -32 if compact_layout else -24
	root.margin_bottom = -16 if compact_layout else -22
	root.add_constant_override("separation", 16 if compact_layout else 12)
	add_child(root)
	header_label = Label.new()
	header_label.text = PersianText.reshaper("مینی زکا سیتی")
	header_label.align = Label.ALIGN_CENTER
	_apply_font(header_label, 28 if compact_layout else 26)
	header_label.add_color_override("font_color", Color("#ffffff"))
	root.add_child(header_label)
	var menu_row = HBoxContainer.new()
	menu_row.alignment = BoxContainer.ALIGN_CENTER
	root.add_child(menu_row)
	var menu_button = Button.new()
	menu_button.text = PersianText.reshaper("☰ منو")
	menu_button.rect_min_size = Vector2(180, 54 if compact_layout else 46)
	_apply_font(menu_button, 20 if compact_layout else 18)
	_style_button(menu_button, true)
	menu_row.add_child(menu_button)

	var help_button = Button.new()
	help_button.text = PersianText.reshaper("؟")
	help_button.hint_tooltip = "راهنمای کامل بازی"
	help_button.rect_min_size = Vector2(58 if compact_layout else 50, 58 if compact_layout else 46)
	help_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_font(help_button, 29 if compact_layout else 25)
	var help_normal = StyleBoxFlat.new()
	help_normal.bg_color = Color("#0f766e")
	help_normal.border_color = Color("#99f6e4")
	help_normal.set_border_width_all(2)
	help_normal.set_corner_radius_all(24)
	var help_hover = StyleBoxFlat.new()
	help_hover.bg_color = Color("#115e59")
	help_hover.border_color = Color("#ccfbf1")
	help_hover.set_border_width_all(2)
	help_hover.set_corner_radius_all(24)
	var help_pressed = StyleBoxFlat.new()
	help_pressed.bg_color = Color("#134e4a")
	help_pressed.border_color = Color("#5eead4")
	help_pressed.set_border_width_all(2)
	help_pressed.set_corner_radius_all(24)
	help_button.add_stylebox_override("normal", help_normal)
	help_button.add_stylebox_override("hover", help_hover)
	help_button.add_stylebox_override("focus", help_hover)
	help_button.add_stylebox_override("pressed", help_pressed)
	help_button.add_color_override("font_color", Color("#ffffff"))
	help_button.add_color_override("font_color_hover", Color("#ffffff"))
	help_button.add_color_override("font_color_pressed", Color("#ffffff"))
	help_button.connect("pressed", self, "_open_help")
	menu_row.add_child(help_button)
	menu_panel = VBoxContainer.new()
	menu_panel.visible = false
	menu_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_panel.add_constant_override("separation", 7)
	root.add_child(menu_panel)
	menu_pause_button = _create_menu_action("⏸ توقف بازی", "toggle_pause")
	_create_menu_action("💾 ذخیره بازی", "save_from_menu")
	_create_menu_action("🔄 شروع دوباره شهر", "confirm_restart_from_menu")
	_create_menu_action("🏙️ بازگشت به شهر من", "return_home_from_menu")
	menu_button.connect("pressed", self, "_toggle_game_menu")
	restart_confirm_panel = VBoxContainer.new()
	restart_confirm_panel.visible = false
	restart_confirm_panel.add_constant_override("separation", 8)
	menu_panel.add_child(restart_confirm_panel)
	var restart_confirm_text = Label.new()
	restart_confirm_text.text = PersianText.reshaper("⚠️ شروع دوباره شهر؟\nتمام پیشرفت فعلی این شهر پاک می‌شود و یک شهر تازه ساخته خواهد شد.")
	restart_confirm_text.align = Label.ALIGN_CENTER
	restart_confirm_text.autowrap = true
	restart_confirm_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart_confirm_text.rect_min_size = Vector2(0, 100 if compact_layout else 76)
	_apply_font(restart_confirm_text, 19 if compact_layout else 17)
	restart_confirm_text.add_color_override("font_color", Color("#fde68a"))
	restart_confirm_panel.add_child(restart_confirm_text)
	var restart_yes_button = Button.new()
	restart_yes_button.text = PersianText.reshaper("بله، شروع دوباره")
	restart_yes_button.rect_min_size = Vector2(0, 54 if compact_layout else 46)
	restart_yes_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(restart_yes_button, 19 if compact_layout else 17)
	_style_button(restart_yes_button, false)
	restart_yes_button.connect("pressed", self, "_restart_city")
	restart_confirm_panel.add_child(restart_yes_button)
	var restart_no_button = Button.new()
	restart_no_button.text = PersianText.reshaper("انصراف")
	restart_no_button.rect_min_size = Vector2(0, 54 if compact_layout else 46)
	restart_no_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(restart_no_button, 19 if compact_layout else 17)
	_style_button(restart_no_button, false)
	restart_no_button.connect("pressed", self, "_cancel_restart")
	restart_confirm_panel.add_child(restart_no_button)
	# Persistent city progression panel: stays visible above navigation on every page.
	var progress_panel = VBoxContainer.new()
	progress_panel.add_constant_override("separation", 3)
	root.add_child(progress_panel)
	level_status_label = Label.new()
	level_status_label.align = Label.ALIGN_CENTER
	level_status_label.add_color_override("font_color", Color("#fbbf24"))
	_apply_font(level_status_label, 17 if compact_layout else 15)
	progress_panel.add_child(level_status_label)
	level_status_bar = ProgressBar.new()
	level_status_bar.min_value = 0
	level_status_bar.max_value = 100
	level_status_bar.value = 100
	level_status_bar.percent_visible = false
	level_status_bar.rect_min_size = Vector2(0, 10 if compact_layout else 8)
	var level_fill = StyleBoxFlat.new()
	level_fill.bg_color = Color("#d97706")
	level_fill.set_corner_radius_all(5)
	level_status_bar.add_stylebox_override("fg", level_fill)
	var level_bg = StyleBoxFlat.new()
	level_bg.bg_color = Color("#334155")
	level_bg.set_corner_radius_all(5)
	level_status_bar.add_stylebox_override("bg", level_bg)
	progress_panel.add_child(level_status_bar)
	xp_progress_label = Label.new()
	xp_progress_label.align = Label.ALIGN_CENTER
	xp_progress_label.add_color_override("font_color", Color("#a5f3fc"))
	_apply_font(xp_progress_label, 15 if compact_layout else 13)
	progress_panel.add_child(xp_progress_label)
	xp_progress_bar = ProgressBar.new()
	xp_progress_bar.min_value = 0
	xp_progress_bar.max_value = 100
	xp_progress_bar.percent_visible = false
	xp_progress_bar.rect_min_size = Vector2(0, 12 if compact_layout else 10)
	var xp_fill = StyleBoxFlat.new()
	xp_fill.bg_color = Color("#06b6d4")
	xp_fill.set_corner_radius_all(5)
	xp_progress_bar.add_stylebox_override("fg", xp_fill)
	var xp_bg = StyleBoxFlat.new()
	xp_bg.bg_color = Color("#334155")
	xp_bg.set_corner_radius_all(5)
	xp_progress_bar.add_stylebox_override("bg", xp_bg)
	progress_panel.add_child(xp_progress_bar)
	_update_progress_hud()
	var nav = GridContainer.new()
	nav.columns = 2 if compact_layout else 3
	nav.add_constant_override("hseparation", 8)
	nav.add_constant_override("vseparation", 8)
	root.add_child(nav)
	for item in [{"t":"شهر من","p":"home"},{"t":"ساختمان‌ها","p":"buildings"},{"t":"شهروندان","p":"citizens"},{"t":"بانک و امور مالی","p":"bank"},{"t":"شهرداری","p":"municipality"},{"t":"اقتصاد خصوصی","p":"private_economy"},{"t":"بازار و تجارت","p":"commerce"},{"t":"جاده و ناوگان","p":"transport"},{"t":"انبار","p":"storage"},{"t":"گزارش","p":"report"},{"t":"ماموریت‌ها","p":"missions"},{"t":"پیشرفت شهر","p":"progress"}]:
		var nav_item = VBoxContainer.new()
		nav_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav_item.add_constant_override("separation", 2)
		if item.p == "missions":
			mission_reward_badge = Label.new()
			mission_reward_badge.text = ""
			mission_reward_badge.align = Label.ALIGN_CENTER
			mission_reward_badge.valign = Label.VALIGN_CENTER
			mission_reward_badge.rect_min_size = Vector2(0, 30)
			mission_reward_badge.add_color_override("font_color", Color("#facc15"))
			mission_reward_badge.add_color_override("font_color_shadow", Color("#111827"))
			mission_reward_badge.modulate = Color("#ffffff")
			_apply_font(mission_reward_badge, 17)
			nav_item.add_child(mission_reward_badge)
		var b = Button.new()
		b.text = PersianText.reshaper(item.t + "  ")
		b.rect_min_size = Vector2(0, 64 if compact_layout else 58)
		b.flat = false
		_apply_font(b, 21 if compact_layout else 18)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(b, true)
		b.connect("pressed", self, "show_page", [item.p])
		nav_item.add_child(b)
		nav.add_child(nav_item)
	var line = HSeparator.new()
	root.add_child(line)
	var scroll = ScrollContainer.new()
	game_scroll_container = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.rect_clip_content = true
	root.add_child(scroll)
	# Hide both scrollbars completely; scrolling remains available by touch/drag.
	var horizontal_bar = scroll.get_h_scrollbar()
	var vertical_bar = scroll.get_v_scrollbar()
	horizontal_bar.visible = false
	vertical_bar.visible = false
	horizontal_bar.modulate = Color(1, 1, 1, 0)
	vertical_bar.modulate = Color(1, 1, 1, 0)
	horizontal_bar.rect_min_size = Vector2(0, 0)
	vertical_bar.rect_min_size = Vector2(0, 0)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.rect_min_size = Vector2(0, 0)
	content.add_constant_override("separation", 16 if compact_layout else 10)
	scroll.add_child(content)
	message_label = Label.new()
	message_label.align = Label.ALIGN_CENTER
	message_label.valign = Label.VALIGN_CENTER
	message_label.autowrap = true
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_label.rect_min_size = Vector2(0, 76 if compact_layout else 58)
	var message_font = _apply_font(message_label, 27 if compact_layout else 23)
	if message_font != null:
		message_font.outline_size = 1
		message_font.outline_color = Color("#101827")
	message_label.add_color_override("font_color", Color("#ffffff"))
	message_label.modulate = Color("#ffffff")
	root.add_child(message_label)

func _update_mission_reward_badge():
	if mission_reward_badge == null or not is_instance_valid(mission_reward_badge) or game == null:
		return
	var ready_to_claim = false
	for mission in game.get_missions():
		if bool(mission.get("completed", false)) and not bool(mission.get("claimed", false)) and bool(mission.get("unlocked", false)):
			ready_to_claim = true
			break
	mission_reward_badge.text = PersianText.reshaper("🎁  جایزه آماده دریافت  🎁" if ready_to_claim else "")
	mission_reward_badge.visible = ready_to_claim

func _create_menu_action(title, callback):
	var button = Button.new()
	button.text = PersianText.reshaper(title)
	button.rect_min_size = Vector2(0, 52 if get_viewport_rect().size.x < 900 else 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(button, 18 if get_viewport_rect().size.x < 900 else 16)
	_style_button(button, false)
	button.connect("pressed", self, callback)
	menu_panel.add_child(button)
	return button

func _toggle_game_menu():
	if menu_panel == null:
		return
	menu_panel.visible = not menu_panel.visible
	_update_menu_pause_button()

func _update_menu_pause_button():
	if menu_pause_button != null:
		menu_pause_button.text = PersianText.reshaper("▶ ادامه بازی" if game_paused else "⏸ توقف بازی")

func toggle_pause():
	game_paused = not game_paused
	_update_menu_pause_button()
	_show_message("بازی متوقف شد." if game_paused else "بازی ادامه پیدا کرد.")

func save_from_menu():
	var saved = game.save_game()
	_show_message("شهر ذخیره شد." if saved else "ذخیره‌سازی ناموفق بود.")
	if menu_panel != null:
		menu_panel.visible = false

func confirm_restart_from_menu():
	if restart_confirm_panel != null:
		restart_confirm_panel.visible = true

func _cancel_restart():
	if restart_confirm_panel != null:
		restart_confirm_panel.visible = false

func return_home_from_menu():
	game_paused = false
	_update_menu_pause_button()
	if menu_panel != null:
		menu_panel.visible = false
	show_page("home")

func _restart_city():
	if restart_confirm_panel != null:
		restart_confirm_panel.visible = false
	if menu_panel != null:
		menu_panel.visible = false
	game_paused = false
	clock_cycle_seconds = 0.0
	clock_save_accumulator = 0.0
	construction_check_accumulator = 0.0
	game.new_game()
	game.state["clock_last_unix"] = OS.get_unix_time()
	game.state["clock_cycle_seconds"] = 0
	game.save_game()
	selected_home_building_id = ""
	selected_demolish_quantity = 1
	show_page("home")
	_show_message("شهر جدید با موفقیت آغاز شد.")

func _update_progress_hud():
	if game == null or level_status_label == null or xp_progress_bar == null:
		return
	var level = max(1, int(game.state.get("level", 1)))
	var xp = max(0, int(game.state.get("xp", 0)))
	var required = max(1, int(game.get_xp_required_for_next_level()))
	var percent = clamp(float(xp) * 100.0 / float(required), 0.0, 100.0)
	var district_count = int(game.state.get("districts", []).size())
	var geographic_rank = _get_geographic_rank_name(district_count)
	level_status_label.text = PersianText.reshaper("سطح شهر %d  |  %s" % [level, geographic_rank])
	xp_progress_label.text = PersianText.reshaper("تجربه شهر: %d٪" % int(round(percent)))
	xp_progress_bar.max_value = required
	xp_progress_bar.value = min(xp, required)
	level_status_bar.value = 100

func _get_geographic_rank_name(district_count):
	# Every three built districts advance the city's geographic rank.
	# A new city starts at the first rank even before its first district is registered.
	var ranks = [
		"آبادی کوچک", "آبادی", "آبادی بزرگ",
		"روستای کوچک", "روستا", "روستای بزرگ",
		"ده کوچک", "ده", "ده بزرگ",
		"دهستان کوچک", "دهستان", "دهستان بزرگ",
		"بخش کوچک", "بخش", "بخش بزرگ",
		"شهر کوچک", "شهر", "شهر بزرگ",
		"شهرستان کوچک", "شهرستان", "شهرستان بزرگ",
		"استان کوچک", "استان", "استان بزرگ",
		"ایالت کوچک", "ایالت", "ایالت بزرگ",
		"کشور کوچک", "کشور", "کشور بزرگ",
		"قاره کوچک", "قاره", "قاره بزرگ",
		"سیاره کوچک", "سیاره", "سیاره بزرگ",
		"منظومه کوچک", "منظومه", "منظومه بزرگ",
		"سامانه ستاره‌ای کوچک", "سامانه ستاره‌ای", "سامانه ستاره‌ای بزرگ",
		"کهکشان کوچک", "کهکشان", "کهکشان بزرگ",
		"گروه کهکشانی کوچک", "گروه کهکشانی", "گروه کهکشانی بزرگ",
		"خوشه کهکشانی کوچک", "خوشه کهکشانی", "خوشه کهکشانی بزرگ",
		"ابرخوشه کهکشانی کوچک", "ابرخوشه کهکشانی", "ابرخوشه کهکشانی بزرگ",
		"شبکه کیهانی کوچک", "شبکه کیهانی", "شبکه کیهانی بزرگ",
		"جهان قابل مشاهده کوچک", "جهان قابل مشاهده", "جهان قابل مشاهده بزرگ",
		"جهان کوچک", "جهان", "جهان بزرگ"
	]
	var safe_count = max(1, int(district_count))
	var rank_index = int(floor(float(safe_count - 1) / 3.0))
	return str(ranks[min(rank_index, ranks.size() - 1)])

func _load_ui_font():
	var font_data = DynamicFontData.new()
	font_data.font_path = "res://assets/fonts/Vazirmatn.ttf"
	# Render the UI font at higher resolution so newly-created labels stay sharp
	# on high-DPI mobile screens and when the HTML5 canvas is scaled.
	font_data.antialiased = true
	font_data.hinting = DynamicFontData.HINTING_NORMAL
	ui_font = DynamicFont.new()
	ui_font.font_data = font_data
	ui_font.size = 20
	# Avoid texture filtering: it softens glyph edges and makes small UI text look blurry.
	ui_font.use_filter = false
	ui_font.use_mipmaps = false

func _apply_font(control, size=18):
	if ui_font == null:
		return
	var font = DynamicFont.new()
	font.font_data = ui_font.font_data
	# Keep the rendered glyph edges crisp instead of smoothing the font texture.
	font.use_filter = false
	font.use_mipmaps = false
	# A thin, high-contrast outline adds visual weight without enlarging glyphs.
	font.size = int(size) + (5 if get_viewport_rect().size.x < 900 else 4)
	font.outline_size = 1
	font.outline_color = Color("#111827")
	control.add_font_override("font", font)
	return font

func _button_style(bg_color, border_color):
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _style_button(button, navigation=false):
	button.flat = false
	# Main buttons: near-black with white text.
	# Inner buttons: clean white with near-black text.
	var normal_color = Color("#202124") if navigation else Color("#FFFFFF")
	var hover_color = Color("#34363A") if navigation else Color("#E8EAED")
	var pressed_color = Color("#111214") if navigation else Color("#DADCE0")
	var border_normal = Color("#050505") if navigation else Color("#73777D")
	var border_hover = Color("#000000") if navigation else Color("#4B5057")
	var border_pressed = Color("#000000") if navigation else Color("#30343A")
	var text_color = Color("#FFFFFF") if navigation else Color("#111111")
	button.add_stylebox_override("normal", _button_style(normal_color, border_normal))
	button.add_stylebox_override("hover", _button_style(hover_color, border_hover))
	button.add_stylebox_override("focus", _button_style(hover_color, border_hover))
	button.add_stylebox_override("pressed", _button_style(pressed_color, border_pressed))
	button.add_stylebox_override("disabled", _button_style(Color("#D1D5DB"), Color("#6B7280")))
	button.add_color_override("font_color", text_color)
	button.add_color_override("font_color_focus", text_color)
	button.add_color_override("font_color_hover", text_color)
	button.add_color_override("font_color_pressed", text_color)
	button.add_color_override("font_color_disabled", Color("#4B5563"))
	var button_font = button.get_font("font")
	if button_font is DynamicFont:
		button_font.outline_size = 1
		button_font.outline_color = Color("#FFFFFF") if not navigation else Color("#111827")

func _clear_content():
	construction_time_labels.clear()
	for child in content.get_children():
		child.queue_free()

func _add_label(text, size=18):
	var label = Label.new()
	label.text = PersianText.reshaper(text)
	label.align = Label.ALIGN_RIGHT
	_apply_font(label, size)
	label.autowrap = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.rect_min_size = Vector2(0, 44 if get_viewport_rect().size.x < 900 else 34)
	label.add_color_override("font_color", Color("#f8fafc"))
	label.add_color_override("font_color_shadow", Color("#0b1220"))
	label.modulate = Color("#ffffff")
	var target = active_section_container if active_section_container != null else content
	target.add_child(label)
	return label

func _add_button(text, button_target, callback, args=[]):
	var button = Button.new()
	button.text = PersianText.reshaper(text + "  ")
	button.rect_min_size = Vector2(0, 58 if get_viewport_rect().size.x < 900 else 50)
	_apply_font(button, 19 if get_viewport_rect().size.x < 900 else 17)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(button, false)
	button.connect("pressed", button_target, callback, args)
	var parent = active_section_container if active_section_container != null else content
	parent.add_child(button)
	return button

func _toggle_commerce_section(section_id):
	commerce_section_expanded[section_id] = not bool(commerce_section_expanded.get(section_id, false))
	show_page("commerce")

func _show_message(text):
	message_label.text = PersianText.reshaper(text)
	if game != null and str(text).strip_edges() != "" and game.has_method("add_report_event"):
		game.add_report_event(str(text))

func _show_welcome_mission_hint():
	# Show the onboarding hint until the first tutorial mission is completed.
	for mission in game.get_missions():
		if str(mission.get("id", "")) == "buy_land_tutorial" and bool(mission.get("completed", false)):
			return
	var panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("#26384d")
	panel_style.border_color = Color("#60a5fa")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	panel.add_stylebox_override("panel", panel_style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(panel)
	var layout = VBoxContainer.new()
	layout.add_constant_override("separation", 8)
	panel.add_child(layout)
	var welcome = Label.new()
	welcome.text = PersianText.reshaper("به شهر خودت خوش اومدی! برای شروع، به مأموریت‌ها برو.")
	welcome.align = Label.ALIGN_CENTER
	welcome.autowrap = true
	welcome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(welcome, 18 if get_viewport_rect().size.x < 900 else 17)
	welcome.add_color_override("font_color", Color("#ffffff"))
	layout.add_child(welcome)
	var go_button = Button.new()
	go_button.text = PersianText.reshaper("رفتن به مأموریت‌ها  ←")
	go_button.rect_min_size = Vector2(0, 54 if get_viewport_rect().size.x < 900 else 46)
	go_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(go_button, 19 if get_viewport_rect().size.x < 900 else 17)
	_style_button(go_button, false)
	go_button.connect("pressed", self, "_open_missions_from_welcome")
	layout.add_child(go_button)


func _open_help():
	show_page("help")
	if game_scroll_container != null and is_instance_valid(game_scroll_container):
		game_scroll_container.scroll_vertical = 0

func _add_help_section(title, description, target_page=""):
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("#1e293b")
	panel_style.border_color = Color("#475569")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	panel.add_stylebox_override("panel", panel_style)
	content.add_child(panel)
	var body = VBoxContainer.new()
	body.add_constant_override("separation", 5)
	panel.add_child(body)
	var heading = Label.new()
	heading.text = PersianText.reshaper(title)
	heading.align = Label.ALIGN_RIGHT
	heading.autowrap = true
	_apply_font(heading, 18 if get_viewport_rect().size.x < 900 else 17)
	heading.add_color_override("font_color", Color("#fbbf24"))
	body.add_child(heading)
	var details = Label.new()
	details.text = PersianText.reshaper(description)
	details.align = Label.ALIGN_RIGHT
	details.autowrap = true
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(details, 16 if get_viewport_rect().size.x < 900 else 15)
	details.add_color_override("font_color", Color("#e2e8f0"))
	body.add_child(details)
	if str(target_page) != "":
		var jump = Button.new()
		jump.text = PersianText.reshaper("رفتن به بخش مربوط  ←")
		jump.rect_min_size = Vector2(0, 48 if get_viewport_rect().size.x < 900 else 42)
		jump.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_font(jump, 16 if get_viewport_rect().size.x < 900 else 15)
		_style_button(jump, false)
		jump.connect("pressed", self, "show_page", [str(target_page)])
		body.add_child(jump)

func _open_missions_from_welcome():
	show_page("missions")
	if game_scroll_container != null and is_instance_valid(game_scroll_container):
		game_scroll_container.scroll_vertical = 0

func show_page(page):
	current_page = page
	# Never let labels/buttons from a previous collapsible section attach to an old page.
	active_section_container = null
	_clear_content()
	_show_message("")
	var s = game.state
	_update_progress_hud()
	_update_mission_reward_badge()
	if page == "home" or page == "buildings":
		var active_constructions = game.get_construction_status()
		_add_label("ظرفیت ساخت‌وساز: %d از %d پروژه فعال" % [game.get_active_construction_count(), game.MAX_CONCURRENT_CONSTRUCTIONS], 17)
		if active_constructions.size() > 0:
			_add_label("🏗️ پروژه‌های در حال ساخت", 19)
			for project in active_constructions:
				var seconds_left = int(project.remaining)
				var time_label = _add_label("%s | زمان باقی‌مانده: %02d:%02d" % [str(project.name), int(seconds_left / 60), seconds_left % 60], 16)
				construction_time_labels.append({"label":time_label,"name":str(project.name)})
	match page:
		"home":
			_add_label("وضعیت کلی شهر", 22)
			_show_welcome_mission_hint()
			_add_label("روز %d  |  سطح شهر %d" % [s.day,s.level], 19)
			var login_reward_status = game.get_login_reward_status()
			_add_label("🎁 زنجیره ورود: %d روز | هدیه امروز: %d سکه" % [int(login_reward_status.streak),int(login_reward_status.reward)],16)
			var weekly_city_event = game.get_weekly_city_event()
			_add_label("🌟 رویداد این هفته: %s" % str(weekly_city_event.get("title","")),17)
			_add_label("%s | اثر: %s" % [str(weekly_city_event.get("description","")),str(weekly_city_event.get("effect",""))],14)
			var login_reward_button = _add_button("🎁 دریافت هدیه ورود روزانه",self,"claim_login_reward")
			login_reward_button.disabled = bool(login_reward_status.claimed) or not bool(login_reward_status.logged_in)

			var pending_decision = game.get_pending_city_decision()
			if not pending_decision.empty():
				_add_label("⚖️ تصمیم مهم شهروندان",20)
				_add_label(str(pending_decision.get("title","تصمیم شهر")),18)
				_add_label(str(pending_decision.get("description","")),15)
				for decision_option in pending_decision.get("options", []):
					_add_button(str(decision_option.get("label","انتخاب")),self,"resolve_city_decision",[str(decision_option.get("id",""))])
			var rival_standings = game.get_rival_standings()
			var my_rank = 0
			for rival_row in rival_standings:
				if bool(rival_row.get("is_player",false)):
					my_rank = int(rival_row.get("rank",0))
			_add_label("🏁 جایگاه فعلی شهر در رقابت: رتبه %d از %d" % [my_rank,rival_standings.size()],16)
			var recent_city_events = s.get("city_event_history",[])
			if not recent_city_events.empty():
				var recent_event = recent_city_events[recent_city_events.size()-1]
				_add_label("🎲 آخرین اتفاق شهر | روز %d: %s" % [int(recent_event.get("day",s.day)),str(recent_event.get("title","رویداد"))],16)
			clock_label = _add_label("روز | زمان باقی‌مانده: 00:07", 18)
			_add_label("خزانه: %d / %d سکه  |  پول قفل‌شده: %d" % [s.money,game.get_treasury_capacity(),game.get_locked_money()], 20)
			_add_label("جمعیت: %d نفر  |  شاغل: %d  |  بیکار: %d" % [s.population,game.get_employed_count(),game.get_unemployed_count()], 19)
			var municipal_economy = s.get("last_economy", {})
			var municipal_daily_income = int(municipal_economy.get("tax_income",0)) + int(municipal_economy.get("consumer_tax_income",0)) + int(municipal_economy.get("station_income",0)) + int(municipal_economy.get("road_income",0))
			var municipal_daily_total = int(municipal_economy.get("accepted_income",0))
			_add_label("درآمد روزانه شهرداری: %d سکه" % municipal_daily_total, 18)
			_add_label("اعتبار شهر: %d  |  رضایت: %d/۱۰۰" % [s.reputation,int(s.get("satisfaction",50))], 18)

			_add_home_services_panel(s)

			var buildings_toggle = _add_button(("▼ " if home_buildings_expanded else "▶ ") + "ساختمان‌های ساخته‌شده", self, "toggle_home_buildings")
			_style_button(buildings_toggle, false)
			if home_buildings_expanded:
				var home_categories = ["خانه‌ها","کشاورزی","معادن","کارخانه‌ها","کسب‌وکارها","خدمات شهری","تفریح و فرهنگ","انبارها"]
				var any_home_building = false
				for home_category in home_categories:
					var category_rows = []
					for home_id in game.get_building_definitions().keys():
						var home_data = game.get_building_definitions()[home_id]
						if str(home_data.get("category","")) == home_category:
							var home_count = game.get_building_count(home_id)
							if home_count > 0:
								category_rows.append({"id":home_id,"name":str(home_data.name),"count":home_count})
					if not category_rows.empty():
						any_home_building = true
						_add_label("【"+home_category+"】", 17)
						for home_row in category_rows:
							_add_label("%s  |  تعداد: %d" % [home_row.name,home_row.count], 16)
				if not any_home_building:
					_add_label("هنوز ساختمانی در شهر ساخته نشده است.", 16)

			var demolish_toggle = _add_button(("▼ " if demolish_panel_expanded else "▶ ") + "مدیریت تخریب ساختمان‌ها", self, "toggle_demolish_panel")
			_style_button(demolish_toggle, false)
			if demolish_panel_expanded:
				_add_label("ساختمان موردنظر را انتخاب کن:", 16)
				for home_id in game.get_building_definitions().keys():
					var home_count = game.get_building_count(home_id)
					if home_count <= 0:
						continue
					var home_data = game.get_building_definitions()[home_id]
					var home_button = _add_button("%s  |  تعداد: %d" % [str(home_data.name),home_count], self, "select_home_building", [home_id])
					_style_button(home_button, false)
					if selected_home_building_id == str(home_id):
						home_button.add_color_override("font_color", Color("#fde68a"))
				if selected_home_building_id != "" and game.get_building_count(selected_home_building_id) > 0:
					var selected_definition = game.get_building_definitions()[selected_home_building_id]
					var selected_count = game.get_building_count(selected_home_building_id)
					_add_label("انتخاب‌شده: %s  |  موجود: %d" % [selected_definition.name,selected_count], 17)
					_add_label("تعداد برای تخریب: %d" % selected_demolish_quantity, 16)
					var quantity_row = HBoxContainer.new()
					quantity_row.add_constant_override("separation", 8)
					content.add_child(quantity_row)
					var less_button = Button.new()
					less_button.text = "−"
					less_button.rect_min_size = Vector2(70,58)
					_apply_font(less_button,24)
					_style_button(less_button,false)
					less_button.connect("pressed",self,"adjust_demolish_quantity",[-1])
					quantity_row.add_child(less_button)
					var more_button = Button.new()
					more_button.text = "+"
					more_button.rect_min_size = Vector2(70,58)
					_apply_font(more_button,24)
					_style_button(more_button,false)
					more_button.connect("pressed",self,"adjust_demolish_quantity",[1])
					quantity_row.add_child(more_button)
					var demolish_button = _add_button("تخریب %d عدد از %s" % [selected_demolish_quantity,selected_definition.name],self,"demolish_selected_buildings")
					_style_button(demolish_button, false)
					if selected_home_building_id == "small_house" and selected_count <= 1:
						demolish_button.disabled = true
				else:
					_add_label("برای تخریب، ابتدا یک ساختمان را انتخاب کن.", 15)

			var economy_toggle = _add_button(("▼ " if home_economy_expanded else "▶ ") + "منابع و گزارش مالی", self, "toggle_home_economy")
			_style_button(economy_toggle, false)
			if home_economy_expanded:
				_add_label("منابع: " + _resource_summary(), 16)
				_add_label("ذخیره غذای شهر: %d واحد" % int(s.resources.get("food",0)), 16)
				var home_economy = s.get("last_economy", {})
				_add_label("آخرین تراز روزانه: %d سکه" % int(home_economy.get("net_cashflow",0)), 17)
				_add_label("درآمد ایستگاه‌ها و پایانه‌ها: %d سکه" % int(home_economy.get("station_income",0)), 16)
				_add_label("عوارض جاده‌ای: %d سکه" % int(home_economy.get("road_income",0)), 16)
			var save_city_button = _add_button("💾 ذخیره شهر", self, "save_now")
			_style_button(save_city_button, false)
		"buildings":
			_add_label("ساخت‌وساز شهر", 22)
			_add_label("زمین شهر: %d قطعه | اشغال‌شده: %d | آزاد: %d" % [int(s.get("land_owned",10)),game.get_land_used(),game.get_land_free()], 19)
			_add_label("برای گسترش شهر باید زمین بخری؛ هر ساختمان چند قطعه از زمین را اشغال می‌کند.", 15)
			var land_button = _add_button("خرید ۱ قطعه زمین | قیمت: %d سکه" % game.get_land_unit_price(), self, "buy_land")
			land_button.disabled = game.get_available_money() < game.get_land_unit_price()
			var categories = ["همه","خانه‌ها","کشاورزی","ماهیگیری","معادن","کارخانه‌ها","کسب‌وکارها","خدمات شهری","تفریح و فرهنگ","انبارها"]
			_add_label("برای دیدن ساختمان‌ها، دسته موردنظر را باز کن:", 18)
			for category in categories:
				var is_expanded = selected_building_category == category
				var category_button = _add_button(("▼ " if is_expanded else "▶ ") + category, self, "select_building_category", [category])
				if is_expanded:
					_add_building_category_items(category)
			if selected_building_category == "همه" or selected_building_category == "معادن":
				_add_label("مدیریت معادن:", 18)
				for mine_index in range(game.get_mines().size()):
					var mine = game.get_mines()[mine_index]
					var mine_status = ("فعال" if bool(mine.get("active",false)) else "متوقف")
					if str(mine.get("resource","")) == "iron_ore":
						mine_status += " | ذخیره: %d" % int(mine.get("remaining",0))
						if int(mine.get("remaining",0)) <= 0:
							_add_button("شارژ معدن آهن — ۱۰۰۰ سکه", self, "refill_mine", [mine_index])
					_add_label("%s — %s" % [game.get_resource_definitions()[str(mine.get("resource","stone"))].name,mine_status])
			_add_label("ساختمان‌ها:", 18)
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
				var expanded = bool(current_district_expanded.get(district_id, false))
				var district_button = _add_button(("▼ " if expanded else "▶ ") + group_name, self, "toggle_current_district", [district_id])
				_style_button(district_button, false)
				if expanded:
					var capacity_info = game.get_district_capacity_summary(district_id)
					_add_label("ظرفیت محله | خانه‌ها: %d/۲۰  •  ساختمان‌های عادی: %d/۲۰  •  اضطراری: %d/۱۰" % [int(capacity_info.get("house_count",0)),int(capacity_info.get("other_count",0)),int(capacity_info.get("emergency_count",0))], 15)
					_add_label("حداکثر ۲ عدد از هر نوع ساختمان؛ سهمیه اضطراری جدا از ظرفیت عادی است.", 14)
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
							_add_label("%s ×%d" % [building_name, building_count], 16)
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
							_add_label("وضعیت تولید: %s" % production_status, 15)
							_add_label("نیروی کار: %d از %d نفر | محصول: %s" % [assigned_workers, required_workers, str(game.get_resource_definitions().get(production_output, {}).get("name", production_output))], 14)
						if int(building.get("balance", 0)) > 0:
							_add_label("حساب %s: %d سکه" % [str(building_definition.get("name", "ساختمان")), int(building.get("balance", 0))], 15)
							_add_button("برداشت سود %s: %d سکه" % [str(building_definition.get("name", "ساختمان")), int(building.get("balance", 0))], self, "collect_profit", [i])
			if district_ids.size() == 0:
				_add_label("هنوز ساختمانی در محله‌ای ساخته نشده است.", 15)
		"citizens":
			_add_label(" جمعیت: %d | شاغل: %d | بیکار: %d" % [s.population,game.get_employed_count(),game.get_unemployed_count()], 20)
			var poor_citizens = 0
			var middle_citizens = 0
			var wealthy_citizens = 0
			for wealth_citizen in s.citizens:
				var citizen_wallet = int(wealth_citizen.get("wallet",0))
				if citizen_wallet < 500:
					poor_citizens += 1
				elif citizen_wallet < 1200:
					middle_citizens += 1
				else:
					wealthy_citizens += 1
			_add_label("وضعیت اقتصادی شهروندان | فقیر: %d نفر  |  متوسط: %d نفر  |  ثروتمند: %d نفر" % [poor_citizens,middle_citizens,wealthy_citizens], 17)
			_add_label("ظرفیت مسکن: %d | ظرفیت شغلی: %d" % [game.get_housing_capacity(),game.get_job_capacity()])
			_add_label("رضایت شهروندان: %d/۱۰۰" % int(s.get("satisfaction",50)))
			_add_label("نیازهای روزانه: " + _needs_summary(), 15)
			var resident_requests = s.get("resident_requests",[])
			_add_label("📣 درخواست‌های شهروندان: %d" % resident_requests.size(),18)
			for resident_request in resident_requests:
				_add_label(str(resident_request.get("title","درخواست شهروندان"))+" | روز "+str(int(resident_request.get("day",s.day))),17)
				_add_label(str(resident_request.get("description","")),15)
				_add_button("رفتن به بخش ساخت ساختمان پیشنهادی  ←",self,"go_to_resident_request_building",[str(resident_request.get("building_id",""))])
				if bool(resident_request.get("accepted",false)):
					_add_label("✓ پذیرفته شده؛ با ساخت ساختمان پیشنهادی، درخواست تکمیل می‌شود.",15)
				else:
					_add_button("پذیرفتن و تعهد ساخت",self,"resolve_resident_request",[int(resident_request.get("id",0)),true])
					_add_button("رد درخواست",self,"resolve_resident_request",[int(resident_request.get("id",0)),false])
			_add_label("روش جذب شهروند: " + ("خودکار" if str(s.get("citizen_recruitment_mode","auto")) == "auto" else "دستی"), 18)
			var auto_recruit_button = _add_button("فعال‌کردن جذب خودکار", self, "set_recruitment_mode", ["auto"])
			var manual_recruit_button = _add_button("فعال‌کردن جذب دستی", self, "set_recruitment_mode", ["manual"])
			auto_recruit_button.disabled = str(s.get("citizen_recruitment_mode","auto")) == "auto"
			manual_recruit_button.disabled = str(s.get("citizen_recruitment_mode","auto")) == "manual"
			_add_label("درخواست‌های در انتظار: %d" % s.get("citizen_requests", []).size(), 18)
			for request_index in range(s.get("citizen_requests", []).size()):
				var request = s.citizen_requests[request_index]
				_add_label("متقاضی شماره %d | درخواست در روز %d" % [int(request.get("id",0)),int(request.get("day",s.day))], 17)
				_add_button("قبول درخواست شماره %d" % int(request.get("id",0)), self, "accept_citizen_request", [request_index])
				_add_button("رد درخواست شماره %d" % int(request.get("id",0)), self, "reject_citizen_request", [request_index])
			if int(s.population) >= game.get_housing_capacity():
				_add_label("ظرفیت خانه‌ها پر است؛ برای جذب شهروند جدید خانه بساز.", 15)
			elif int(s.reputation) < 25:
				_add_label("اعتبار شهر باید حداقل ۲۵ باشد تا متقاضی جدید بیاید.", 15)
			var citizen_groups = {"بیکاران":[],"کارمندان شهرداری":[],"کارمندان بخش خصوصی":[],"کارآفرینان بخش خصوصی":[]}
			for citizen in s.citizens:
				var group_name = "بیکاران"
				if str(citizen.get("job","")) != "":
					group_name = "کارمندان شهرداری"
				elif int(citizen.get("private_business_id",0)) > 0:
					group_name = "کارآفرینان بخش خصوصی"
				elif int(citizen.get("private_job_id",0)) > 0:
					group_name = "کارمندان بخش خصوصی"
				citizen_groups[group_name].append(citizen)
			for group_name in ["بیکاران","کارمندان شهرداری","کارمندان بخش خصوصی","کارآفرینان بخش خصوصی"]:
				var group_citizens = citizen_groups[group_name]
				if group_citizens.empty():
					continue
				var group_expanded = bool(citizen_status_expanded.get(group_name,false))
				var group_button = _add_button(("%s " % ("▼" if group_expanded else "▶")) + "%s (%d)" % [group_name,group_citizens.size()], self, "toggle_citizen_status_group", [group_name])
				_style_button(group_button,false)
				if group_expanded:
					for citizen in group_citizens:
						var citizen_role = group_name
						if str(citizen.get("job","")) != "":
							citizen_role += ": " + str(citizen.job)
						_add_label("شهروند %s — %s | کیف پول: %d سکه | زمین خصوصی: %d قطعه" % [str(citizen.id),citizen_role,int(citizen.get("wallet",0)),int(citizen.get("private_land",0))])
						var interest_names = {"food":"خوراک","industry":"صنعت","services":"خدمات"}
						_add_label("استعداد کارآفرینی: %d | ریسک‌پذیری: %d | علاقه: %s | پس‌انداز: %d" % [int(citizen.get("entrepreneurship",0)),int(citizen.get("risk_tolerance",0)),str(interest_names.get(str(citizen.get("business_interest","")),"نامشخص")),int(citizen.get("saving_habit",0))], 14)
			_add_button(" تخصیص دوباره شغل‌ها", self, "reassign_jobs")
		"bank":
			_add_label("🏦 بانک و امور مالی شهر",22)
			_add_label("بانک مرکزی: %s | بانک شهری: %d" % ["فعال" if game.has_central_bank() else "ساخته نشده",game.get_building_count("municipal_bank")],17)
			_add_label("وام فقط با بانک مرکزی و سپرده‌گذاری با بانک شهری فعال می‌شود.",15)
			_add_label("موجودی خزانه: %d سکه | ظرفیت آزاد: %d سکه" % [int(s.money),game.get_available_money()],16)
			_add_label("حداکثر وام قابل دریافت: %d سکه" % game.get_bank_loan_limit(),16)
			var player_active_loans = 0
			for player_loan in s.get("bank_loans", []):
				if str(player_loan.get("status", "active")) == "active":
					player_active_loans += 1
			_add_label("وام‌های فعال شهرداری: %d از ۲" % player_active_loans,16)
			_add_label("شهروندان شاغل و کم‌پول نیز در صورت فعال‌بودن بانک مرکزی، خودکار وام می‌گیرند؛ سقف هر شهروند ۲ وام فعال است و قسط از کیف پول خودش کم می‌شود.",15)
			var citizen_active_loans = 0
			for bank_citizen in s.get("citizens", []):
				for citizen_loan in bank_citizen.get("bank_loans", []):
					if str(citizen_loan.get("status", "active")) == "active":
						citizen_active_loans += 1
			_add_label("وام‌های فعال شهروندان: %d" % citizen_active_loans,16)
			_add_label("💳 دریافت وام",19)
			for loan_option in [{"amount":1000,"days":7},{"amount":3000,"days":14},{"amount":5000,"days":30}]:
				var loan_button = _add_button("درخواست وام %d سکه‌ای — %d روزه" % [int(loan_option.amount),int(loan_option.days)],self,"request_bank_loan",[int(loan_option.amount),int(loan_option.days)])
				loan_button.disabled = not game.has_central_bank() or game.get_bank_loan_limit() < int(loan_option.amount) or player_active_loans >= 2
			for loan_index in range(s.get("bank_loans",[]).size()):
				var loan = s.bank_loans[loan_index]
				_add_label("وام #%d | اصل: %d | سود: %d | مانده: %d | وضعیت: %s" % [int(loan.get("id",loan_index+1)),int(loan.get("principal",0)),int(loan.get("interest",0)),int(loan.get("remaining",0)),"فعال" if str(loan.get("status","")) == "active" else "تسویه‌شده"],15)
				if str(loan.get("status","")) == "active":
					var manual_button = _add_button("پرداخت دستی قسط وام #%d — تا %d سکه" % [int(loan.get("id",loan_index+1)),min(int(loan.get("remaining",0)),int(loan.get("daily_installment",0)))],self,"repay_bank_loan_manual",[loan_index])
					manual_button.disabled = int(loan.get("last_manual_payment_day",0)) == int(s.get("day",1)) or game.get_available_money() <= 0
					var full_button = _add_button("تسویه کامل وام #%d — %d سکه" % [int(loan.get("id",loan_index+1)),int(loan.get("remaining",0))],self,"repay_bank_loan",[loan_index])
					full_button.disabled = game.get_available_money() < int(loan.get("remaining",0))
			_add_label("🏧 سپرده‌گذاری",19)
			_add_label("سود کل سپرده: ۷ روز ۳٪ | ۱۴ روز ۷٪ | ۳۰ روز ۱۵٪؛ برداشت پیش از سررسید بدون سود است.",14)
			for deposit_option in [{"amount":500,"days":7},{"amount":1000,"days":14},{"amount":2500,"days":30}]:
				var deposit_button = _add_button("سپرده %d سکه‌ای — %d روزه" % [int(deposit_option.amount),int(deposit_option.days)],self,"open_bank_deposit",[int(deposit_option.amount),int(deposit_option.days)])
				deposit_button.disabled = game.get_building_count("municipal_bank") <= 0 or game.get_available_money() < int(deposit_option.amount)
			for deposit_index in range(s.get("bank_deposits",[]).size()):
				var deposit = s.bank_deposits[deposit_index]
				var deposit_status = str(deposit.get("status","active"))
				if deposit_status == "withdrawn":
					continue
				_add_label("سپرده #%d | اصل: %d | سود: %d | سررسید: روز %d | %s" % [int(deposit.get("id",deposit_index+1)),int(deposit.get("principal",0)),int(deposit.get("interest",0)),int(deposit.get("maturity_day",0)),"آماده برداشت" if deposit_status == "matured" or int(s.day) >= int(deposit.get("maturity_day",0)) else "در حال سپرده"],15)
				_add_button("برداشت سپرده #%d" % int(deposit.get("id",deposit_index+1)),self,"withdraw_bank_savings",[deposit_index])
			_add_label("📜 گردش حساب و سوابق مالی",19)
			if s.get("bank_transactions",[]).empty():
				_add_label("هنوز تراکنش بانکی ثبت نشده است.",15)
			else:
				for transaction_index in range(s.bank_transactions.size()-1,-1,-1):
					var transaction = s.bank_transactions[transaction_index]
					_add_label("روز %d | %s | %d سکه | %s" % [int(transaction.get("day",0)),str(transaction.get("kind","")),int(transaction.get("amount",0)),str(transaction.get("description",""))],14)
		"municipality":
			var civic = game.get_civic_overview()
			_add_label("🏛️ شهرداری و مدیریت اقتصاد شهر", 22)
			_municipality_section("🟨 زمین و قیمت‌گذاری", "land")
			_add_label("زمین خصوصی آماده فروش: %d قطعه | قیمت هر قطعه: %d سکه" % [int(civic.get("private_land_available",0)),int(civic.get("private_land_price",300))], 17)
			_add_button("کاهش قیمت زمین خصوصی ۵۰ سکه", self, "adjust_private_land_price", [-50])
			_add_button("افزایش قیمت زمین خصوصی ۵۰ سکه", self, "adjust_private_land_price", [50])
			_end_municipality_section()
			_municipality_section("💰 مالیات و مجوزها", "tax")
			_add_label("نرخ مالیات کسب‌وکارهای خصوصی: %d درصد" % int(civic.get("tax_rate",8)), 18)
			var tax_down = _add_button("کاهش مالیات خصوصی ۱٪", self, "adjust_business_tax", [-1])
			var tax_up = _add_button("افزایش مالیات خصوصی ۱٪", self, "adjust_business_tax", [1])
			tax_down.disabled = int(civic.get("tax_rate",8)) <= 0
			tax_up.disabled = int(civic.get("tax_rate",8)) >= 30
			_add_label("هزینه صدور مجوز: %d سکه | درآمد مالیات امروز: %d سکه" % [int(civic.get("permit_fee",50)),int(civic.get("daily_tax",0))], 16)
			_add_button("کاهش هزینه مجوز ۱۰ سکه", self, "adjust_business_permit_fee", [-10])
			_add_button("افزایش هزینه مجوز ۱۰ سکه", self, "adjust_business_permit_fee", [10])
			_add_label("درآمد فروش زمین و صدور مجوز جدا از مالیات محاسبه می‌شود.", 15)
			_end_municipality_section()
			_municipality_section("📨 درخواست‌های شهروندان", "requests")
			_add_label("درخواست‌های شهروندان برای بررسی شهرداری: %d" % int(civic.get("request_count",0)), 19)
			if civic.get("requests", []).empty():
				_add_label("درخواستی در انتظار بررسی نیست.", 16)
			for municipal_request in civic.get("requests", []):
				_add_label("%s | شهروند شماره %d | روز %d | مبلغ: %d سکه" % [str(municipal_request.get("title","درخواست شهروند")),int(municipal_request.get("citizen_id",0)),int(municipal_request.get("day",s.day)),int(municipal_request.get("amount",0))], 17)
				_add_button("تأیید درخواست", self, "resolve_civic_request", [int(municipal_request.get("id",0)), true])
				_add_button("رد درخواست", self, "resolve_civic_request", [int(municipal_request.get("id",0)), false])
			_end_municipality_section()
			_municipality_section("🏢 املاک و درآمد اجاره", "properties")
			_add_label("مجموع درآمد اجاره املاک شهرداری (جدا از مالیات): %d سکه" % int(civic.get("rent_income",0)), 16)
			_add_label("املاک تجاری شهرداری:", 18)
			var municipal_property_count = 0
			for property_index in range(s.buildings.size()):
				var property = s.buildings[property_index]
				var property_data = game.get_building_definitions().get(str(property.get("id","")), {})
				var property_category = str(property_data.get("category",""))
				if property_category != "کسب‌وکارها" and property_category != "کارخانه‌ها":
					continue
				municipal_property_count += 1
				if int(property.get("rented_to",0)) > 0:
					_add_label("%s | اجاره‌داده‌شده به شهروند %d | تا روز %d" % [str(property_data.get("name","ملک")),int(property.get("rented_to",0)),int(property.get("rent_until_day",0))],15)
				else:
					_add_label("%s | متعلق به شهرداری | آماده اجاره با درخواست شهروند" % str(property_data.get("name","ملک")),15)
			if municipal_property_count == 0:
				_add_label("هنوز ملک تجاری متعلق به شهرداری ساخته نشده است.", 16)
			_end_municipality_section()
			_municipality_section("🏗️ پروژه‌های عمرانی", "projects")
			_add_label("پروژه‌های عمرانی در حال اجرا: %d" % int(civic.get("project_count",0)), 17)
			for civic_project in civic.get("projects", []):
				_add_label("%s | تحویل روز %d | اعتبار مالیاتی: %d سکه" % [str(game.get_building_definitions().get(str(civic_project.get("building_id","")),{}).get("name","پروژه")),int(civic_project.get("finish_day",0)),int(civic_project.get("tax_credit",0))], 15)
			_end_municipality_section()
		"private_economy":
			var private_economy_data = game.get_civic_overview()
			_add_label("🏙️ اقتصاد خصوصی و مشارکت مردمی", 22)
			_add_label("این بخش با تصمیم شهروندان اداره می‌شود؛ مردم می‌توانند سرمایه‌گذاری کنند، شغل بسازند و برای توسعه خدمات عمومی پیشنهاد بدهند.", 15)
			_add_label("کسب‌وکار خصوصی: %d | فروش روزانه: %d سکه" % [int(private_economy_data.get("business_count",0)),int(private_economy_data.get("daily_revenue",0))], 18)
			_add_label("سرمایه در گردش: %d | مالیات امروز: %d سکه | نرخ مالیات: %d٪" % [int(private_economy_data.get("private_balance",0)),int(private_economy_data.get("daily_tax",0)),int(private_economy_data.get("tax_rate",8))], 16)
			_add_label("زمین خصوصی آزاد: %d قطعه | قیمت هر قطعه: %d | هزینه مجوز: %d" % [int(private_economy_data.get("private_land_available",0)),int(private_economy_data.get("private_land_price",0)),int(private_economy_data.get("permit_fee",0))], 15)
			_add_label("درخواست‌های منتظر تصمیم شهرداری: %d" % int(private_economy_data.get("request_count",0)), 18)
			for request in private_economy_data.get("requests", []):
				var request_type = str(request.get("type",""))
				var citizen_id = int(request.get("citizen_id",0))
				_add_label("📨 %s | متقاضی: شهروند %d | روز %d" % [str(request.get("title","درخواست شهروند")),citizen_id,int(request.get("day",s.day))], 16)
				if request_type == "community_project":
					_add_label("هزینه پروژه: %d | سهم مردم: %d | سهم شهرداری: %d" % [int(request.get("amount",0)),int(request.get("contribution",0)),int(request.get("municipal_amount",0))], 15)
				elif request_type == "permit":
					_add_label("هزینه کسب‌وکار و مجوز: %d | زمین موردنیاز: %d قطعه" % [int(request.get("amount",0)),int(request.get("footprint",1))], 15)
				elif request_type == "land":
					_add_label("تعداد زمین: %d | مبلغ معامله: %d" % [int(request.get("plots",1)),int(request.get("amount",0))], 15)
				elif request_type == "rent":
					_add_label("اجاره روزانه: %d | مبلغ ۷ روز: %d" % [int(request.get("daily_rent",0)),int(request.get("amount",0))], 15)
				elif request_type == "public_project":
					_add_label("هزینه پروژه با سرمایه کسب‌وکار: %d" % int(request.get("amount",0)), 15)
				var request_row = HBoxContainer.new()
				request_row.add_constant_override("separation", 8)
				content.add_child(request_row)
				var approve_button = Button.new()
				approve_button.text = "تأیید"
				_style_button(approve_button,false)
				_apply_font(approve_button,16)
				approve_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				approve_button.connect("pressed",self,"resolve_private_request",[int(request.get("id",0)),true])
				request_row.add_child(approve_button)
				var reject_button = Button.new()
				reject_button.text = "رد درخواست"
				_style_button(reject_button,false)
				_apply_font(reject_button,16)
				reject_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				reject_button.connect("pressed",self,"resolve_private_request",[int(request.get("id",0)),false])
				request_row.add_child(reject_button)
			if private_economy_data.get("requests", []).empty():
				_add_label("درخواستی در انتظار نیست. شهروندان با توجه به نیازهای شهر و سرمایه‌شان پیشنهادهای تازه می‌سازند.", 15)
			_add_label("🏗️ پروژه‌های مشارکتی در حال اجرا: %d" % int(private_economy_data.get("project_count",0)), 18)
			for project in private_economy_data.get("projects", []):
				var project_data = game.get_building_definitions().get(str(project.get("building_id","")),{"name":"پروژه شهری"})
				_add_label("%s | پیشنهاددهنده: شهروند %d | تحویل روز %d" % [str(project_data.get("name","پروژه شهری")),int(project.get("citizen_id",0)),int(project.get("finish_day",0))], 15)
				_add_label("سهم مردم: %d | سهم شهرداری: %d" % [int(project.get("citizen_contribution",0)),int(project.get("municipal_contribution",0))], 14)
			_add_label("🏪 کسب‌وکارهای مردم", 19)
			if private_economy_data.get("private_businesses", []).empty():
				_add_label("هنوز کسب‌وکار خصوصی تأسیس نشده؛ مردم پس از پس‌انداز، برای زمین، اجاره ملک یا مجوز کسب‌وکار درخواست می‌دهند.", 15)
			for business in private_economy_data.get("private_businesses", []):
				_add_label("%s | مالک: شهروند %d | کارمند: %d | فروش روزانه: %d سکه" % [str(business.get("name","کسب‌وکار")),int(business.get("owner_citizen_id",0)),business.get("employees",[]).size(),int(business.get("last_revenue",0))], 16)
				_add_label("سرمایه: %d | مالیات: %d | اعتبار مالیاتی پروژه‌ها: %d" % [int(business.get("balance",0)),int(business.get("last_tax",0)),int(business.get("tax_credit",0))], 14)
				if bool(business.get("rented_municipal",false)):
					_add_label("ملک شهرداری؛ پایان اجاره: روز %d" % int(business.get("rent_until_day",0)), 14)
			_add_label("🧠 هوش و توان شهروندان", 19)
			_add_label("تصمیم مردم بر اساس سرمایه، کارآفرینی، ریسک‌پذیری، خلاقیت، علاقه شغلی، رضایت عمومی و کمبود خدمات شهر گرفته می‌شود.", 15)
			for citizen_index in range(min(8,s.citizens.size())):
				var resident = s.citizens[citizen_index]
				_add_label("شهروند %d | کیف پول: %d | کارآفرینی: %d | خلاقیت: %d | مشارکت اجتماعی: %d" % [int(resident.get("id",citizen_index+1)),int(resident.get("wallet",0)),int(resident.get("entrepreneurship",0)),int(resident.get("creativity",0)),int(resident.get("civic_mindedness",0))], 14)

		"commerce":
			_add_label("🛒 بازار، تجارت و واردات", 22)
			_add_label("فهرست استان‌های تجاری هر روز تغییر می‌کند و با ارتقای سطح شهر، گزینه‌های بیشتری آزاد می‌شود.", 15)
			_add_button(("▼ " if commerce_section_expanded.domestic else "▶ ") + "بازار داخلی و خریدوفروش", self, "_toggle_commerce_section", ["domestic"])
			if commerce_section_expanded.domestic:
				_add_label("قیمت‌ها بر اساس عرضه و تقاضا تغییر می‌کنند.", 15)
				for id in game.get_resource_definitions().keys():
					var d = game.get_resource_definitions()[id]
					var stock = int(s.resources.get(id,0))
					var market_stock = int(s.market_stock.get(id,0))
					var buy_price = game.get_market_price(id,"buy")
					var sell_price = game.get_market_price(id,"sell")
					_add_label("%s | انبار: %d | بازار: %d/۱۰۰ | خرید: %d | فروش: %d" % [d.name,stock,market_stock,buy_price,sell_price])
					var buy_button = _add_button("خرید ۵ واحد "+d.name, self, "buy_item", [id,5])
					buy_button.disabled = int(s.market_stock.get(id,0)) < 5 or game.get_free_storage() < 5 or game.get_available_money() < buy_price * 5
					var sell_button = _add_button("فروش ۵ واحد "+d.name, self, "sell_item", [id,5])
					sell_button.disabled = stock < 5 or int(s.market_stock.get(id,0)) > 95 or game.get_available_money() >= game.get_treasury_capacity()
			_add_button(("▼ " if commerce_section_expanded.export else "▶ ") + "صادرات به استان‌ها", self, "_toggle_commerce_section", ["export"])
			if commerce_section_expanded.export:
				var trade_ids = game.get_daily_trade_city_ids()
				_add_label("استان‌های فعال امروز: %d | ظرفیت حمل آزاد: %d واحد" % [trade_ids.size(),game.get_transport_capacity_remaining()],16)
				_add_label("هر استان فقط کالاهای موردنیاز خودش را می‌خرد؛ کالاهای دیگر برای صادرات به آن استان پذیرفته نمی‌شوند. فهرست فردا تغییر می‌کند.",14)
				for city_id in trade_ids:
					var city = game.get_trade_cities()[city_id]
					_add_label("%s | ظرفیت باقی‌مانده: %d از %d واحد" % [city.name,int(s.trade_remaining.get(city_id,city.daily_capacity)),int(city.daily_capacity)],18)
					for resource_id in game.get_resource_definitions().keys():
						var export_price = game.get_trade_export_price(city_id,resource_id)
						if export_price <= 0:
							continue
						var city_demand_left = int(s.trade_demand_remaining.get(city_id,city.demand).get(resource_id,0))
						_add_label("%s | تقاضا: %d | قیمت صادرات: %d سکه" % [game.get_resource_definitions()[resource_id].name,city_demand_left,export_price],15)
						var export_button = _add_button("صادرات ۵ واحد "+game.get_resource_definitions()[resource_id].name+" به "+city.name,self,"export_to_city",[city_id,resource_id,5])
						export_button.disabled = int(s.resources.get(resource_id,0)) <= 0 or int(s.trade_remaining.get(city_id,city.daily_capacity)) <= 0 or game.get_transport_capacity_remaining() <= 0
				_add_label("آخرین معامله: "+str(s.get("last_trade_report","هنوز معامله‌ای انجام نشده است.")),16)
			_add_button(("▼ " if commerce_section_expanded.import else "▶ ") + "واردات از استان‌ها", self, "_toggle_commerce_section", ["import"])
			if commerce_section_expanded.import:
				var import_ids = game.get_daily_trade_city_ids()
				_add_label("استان‌های فعال امروز: %d | ظرفیت کامیون آزاد: %d از %d واحد" % [import_ids.size(),game.get_transport_capacity_remaining(),game.get_transport_daily_capacity()],16)
				_add_label("هزینه کالا و ۱۰٪ کرایه حمل هنگام سفارش پرداخت می‌شود؛ زمان تحویل بسته به فاصله استان است.",15)
				for city_id in import_ids:
					var city = game.get_import_cities()[city_id]
					_add_label("%s | زمان حمل: %d روز" % [city.name,int(city.travel_days)],18)
					for resource_id in game.get_resource_definitions().keys():
						var import_stock = int(s.city_export_stock.get(city_id,city.supply).get(resource_id,0))
						var price = game.get_import_price(city_id,resource_id)
						if import_stock <= 0:
							continue
						_add_label("%s | موجودی: %d | قیمت: %d سکه/واحد" % [game.get_resource_definitions()[resource_id].name,import_stock,price],15)
						var import_button = _add_button("سفارش ۵ واحد "+game.get_resource_definitions()[resource_id].name+" از "+city.name,self,"import_from_city",[city_id,resource_id,5])
						import_button.disabled = game.get_free_storage() < 5 or game.get_transport_capacity_remaining() < 5 or game.get_available_money() < (5 * price + int(ceil(float(5 * price) * 0.10)))
			_add_button(("▼ " if commerce_section_expanded.shipments else "▶ ") + "محموله‌های در راه", self, "_toggle_commerce_section", ["shipments"])
			if commerce_section_expanded.shipments:
				if s.trade_shipments.empty():
					_add_label("محموله‌ای در راه نیست.")
				for shipment in s.trade_shipments:
					var shipment_city = game.get_import_cities().get(str(shipment.get("city_id","")) ,{"name":"نامشخص"})
					var shipment_resource = game.get_resource_definitions().get(str(shipment.get("resource_id","")) ,{"name":"کالای نامشخص"})
					_add_label("#%d | %s | %d واحد %s | تحویل روز %d" % [int(shipment.get("id",0)),shipment_city.name,int(shipment.get("amount",0)),shipment_resource.name,int(shipment.get("arrival_day",0))],15)
				_add_label("آخرین سفارش: "+str(s.get("last_import_report","")),15)
			_add_button(("▼ " if commerce_section_expanded.contracts else "▶ ") + "قراردادهای واردات", self, "_toggle_commerce_section", ["contracts"])
			if commerce_section_expanded.contracts:
				if s.import_contracts.empty():
					_add_label("قرارداد فعالی ثبت نشده است.")
				for contract_index in range(s.import_contracts.size()):
					var contract = s.import_contracts[contract_index]
					var contract_city = game.get_import_cities().get(str(contract.get("city_id","")) ,{"name":"نامشخص"})
					var contract_resource = game.get_resource_definitions().get(str(contract.get("resource_id","")) ,{"name":"نامشخص"})
					var active_label = "فعال" if bool(contract.get("active",false)) else "پایان‌یافته/لغوشده"
					_add_label("%s | %s | روزانه %d واحد | %d روز باقی‌مانده | %s" % [contract_city.name,contract_resource.name,int(contract.get("daily_amount",0)),int(contract.get("days_left",0)),active_label],15)
					if bool(contract.get("active",false)):
						_add_button("لغو قرارداد "+contract_resource.name,self,"cancel_import",[contract_index])
				for import_city_id in game.get_daily_trade_city_ids():
					var import_city = game.get_import_cities()[import_city_id]
					_add_button("قرارداد ۷ روزه: ۲ واحد چوب از "+import_city.name,self,"make_import_contract",[import_city_id,"wood",2,7])
		"transport":
			_add_label("🛣️ جاده‌ها و حمل‌ونقل شهری و بین‌شهری",22)
			_add_label("جاده‌های اصلی شهر و مسیرهای بین‌شهری",19)
			_add_label("سطح جاده‌های بین‌شهری: %d از ۳" % int(s.get("road_level",1)),17)
			var road_level = int(s.get("road_level",1))
			if road_level < 3:
				var next_road_cost = 1500 if road_level == 1 else 3500
				var road_button = _add_button("احداث و ارتقای مسیر بین‌شهری به سطح %d — %d سکه" % [road_level+1,next_road_cost],self,"upgrade_road")
				road_button.disabled = int(s.level) < road_level+1 or game.get_available_money() < next_road_cost
			else:
				_add_label("مسیرهای بین‌شهری به بالاترین سطح رسیده‌اند.")
			_add_label("🚏 ایستگاه‌های حمل‌ونقل شهری",19)
			_add_label("ایستگاه اتوبوس: %d | ایستگاه تاکسی: %d" % [game.get_building_count("bus_station"),game.get_building_count("taxi_station")],16)
			for facility_id in ["bus_station","taxi_station"]:
				var facility = game.get_building_definitions().get(facility_id,{})
				if facility.empty():
					continue
				var facility_button = _add_button("ساخت "+str(facility.get("name","ایستگاه"))+" — %d سکه | زمین: %d قطعه" % [int(facility.get("cost",0)),game.get_land_size(facility_id)],self,"build_transport_facility",[facility_id])
				facility_button.disabled = int(s.level) < int(facility.get("level_unlock",1))
			_add_label("🚚 پایانه و ناوگان کامیون",19)
			_add_label("پایانه حمل‌ونقل: %d | کامیون فعال: %d | ظرفیت روزانه: %d واحد" % [game.get_building_count("transport_depot"),game.get_transport_truck_count(),game.get_transport_daily_capacity()],17)
			_add_label("ظرفیت مصرف‌شده امروز: %d | ظرفیت باقی‌مانده: %d" % [int(s.get("transport_used_today",0)),game.get_transport_capacity_remaining()],16)
			_add_label("هر پایانه با ۲ کارمند، یک کامیون را فعال می‌کند؛ هر پایانه حداکثر ۲ کامیون پشتیبانی می‌کند.",15)
			_add_label("نگهداری روزانه ناوگان: %d سکه | نگهداری جاده: %d سکه" % [game.get_fleet_maintenance(),game.get_road_maintenance()],16)
			var depot = game.get_building_definitions().get("transport_depot",{})
			if not depot.empty():
				var depot_button = _add_button("ساخت پایانه حمل‌ونقل — %d سکه | زمین: %d قطعه" % [int(depot.get("cost",0)),game.get_land_size("transport_depot")],self,"build_transport_facility",["transport_depot"])
				depot_button.disabled = int(s.level) < int(depot.get("level_unlock",1))
			_add_label("ظرفیت کامیون‌ها بین واردات، قراردادهای تأمین و صادرات مشترک است.",15)
		"imports":
			_add_label(" واردات و حمل‌ونقل بین‌شهری", 22)
			_add_label("ظرفیت کامیون آزاد امروز: %d از %d واحد" % [game.get_transport_capacity_remaining(),game.get_transport_daily_capacity()],16)
			_add_label("هزینه کالا و ۱۰٪ کرایه حمل هنگام سفارش پرداخت می‌شود. محموله پس از ۱ یا ۲ روز می‌رسد.",15)
			for city_id in game.get_import_cities().keys():
				var city = game.get_import_cities()[city_id]
				_add_label("%s | زمان حمل: %d روز" % [city.name,int(city.travel_days)],18)
				for resource_id in game.get_resource_definitions().keys():
					var stock = int(s.city_export_stock.get(city_id,city.supply).get(resource_id,0))
					var price = game.get_import_price(city_id,resource_id)
					if stock <= 0:
						continue
					_add_label("%s | موجودی: %d | قیمت: %d سکه/واحد" % [game.get_resource_definitions()[resource_id].name,stock,price],15)
					var import_button = _add_button("سفارش ۵ واحد "+game.get_resource_definitions()[resource_id].name+" از "+city.name,self,"import_from_city",[city_id,resource_id,5])
					import_button.disabled = game.get_free_storage() < 5 or game.get_transport_capacity_remaining() < 5 or game.get_available_money() < (5 * price + int(ceil(float(5 * price) * 0.10)))
			_add_label(" محموله‌های در راه:",18)
			if s.trade_shipments.empty():
				_add_label("محموله‌ای در راه نیست.")
			for shipment in s.trade_shipments:
				var shipment_city = game.get_import_cities().get(str(shipment.get("city_id","")),{"name":"نامشخص"})
				var shipment_resource = game.get_resource_definitions().get(str(shipment.get("resource_id","")),{"name":"کالای نامشخص"})
				_add_label("#%d | %s | %d واحد %s | تحویل روز %d" % [int(shipment.get("id",0)),shipment_city.name,int(shipment.get("amount",0)),shipment_resource.name,int(shipment.get("arrival_day",0))],15)
			_add_label("آخرین سفارش: "+str(s.get("last_import_report","")),15)
			_add_label(" قراردادهای واردات:",18)
			if s.import_contracts.empty():
				_add_label("قرارداد فعالی ثبت نشده است.")
			for contract_index in range(s.import_contracts.size()):
				var contract = s.import_contracts[contract_index]
				var contract_city = game.get_import_cities().get(str(contract.get("city_id","")),{"name":"نامشخص"})
				var contract_resource = game.get_resource_definitions().get(str(contract.get("resource_id","")),{"name":"نامشخص"})
				var active_label = "فعال" if bool(contract.get("active",false)) else "پایان‌یافته/لغوشده"
				_add_label("%s | %s | روزانه %d واحد | %d روز باقی‌مانده | %s" % [contract_city.name,contract_resource.name,int(contract.get("daily_amount",0)),int(contract.get("days_left",0)),active_label],15)
				if bool(contract.get("active",false)):
					_add_button("لغو قرارداد "+contract_resource.name,self,"cancel_import",[contract_index])
			for city_id in game.get_import_cities().keys():
				var city = game.get_import_cities()[city_id]
				_add_button("قرارداد ۷ روزه: ۲ واحد چوب از "+city.name,self,"make_import_contract",[city_id,"wood",2,7])
		"storage":
			_add_label("مدیریت و تنظیم خودکار انبار", 22)
			_add_label("ظرفیت: %d | مصرف‌شده: %d | فضای خالی: %d" % [game.get_storage_capacity(),game.get_storage_used(),game.get_free_storage()])
			_add_label("برای هر ماده حداقل و حداکثر موجودی تعیین کن. تنظیمات در پایان هر روز اجرا می‌شوند.",15)
			_add_label("اگر موجودی از حداقل کمتر شود، می‌توانی خرید از بازار یا افزایش تولید کارخانه را انتخاب کنی؛ اگر از حداکثر بیشتر شود، فروش خودکار انجام می‌شود.",15)
			for id in game.get_resource_definitions().keys():
				var resource_name = str(game.get_resource_definitions()[id].name)
				var rule = game.get_storage_rule(id)
				var current_amount = int(s.resources.get(id,0))
				var market_amount = int(s.market_stock.get(id,0))
				var is_expanded = bool(storage_section_expanded.get(str(id), false))
				var section_button = _add_button(("▼ " if is_expanded else "▶ ") + resource_name + " | موجودی: %d" % current_amount,self,"toggle_storage_section",[str(id)])
				_style_button(section_button,false)
				if not is_expanded:
					continue
				var section_body = VBoxContainer.new()
				section_body.add_constant_override("separation",5)
				section_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				content.add_child(section_body)
				active_section_container = section_body
				_add_label("موجودی انبار: %d | موجودی بازار: %d" % [current_amount,market_amount],16)
				_add_label("حداقل موجودی: %d | حداکثر موجودی: %d" % [int(rule.get("minimum",10)),int(rule.get("maximum",40))],16)
				var controls = HBoxContainer.new()
				controls.add_constant_override("separation",6)
				controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				active_section_container.add_child(controls)
				var low_down = Button.new()
				low_down.text = PersianText.reshaper("حداقل −")
				_style_button(low_down,false)
				_apply_font(low_down,16)
				low_down.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				low_down.connect("pressed",self,"adjust_storage_rule",[id,"minimum",-5])
				controls.add_child(low_down)
				var low_up = Button.new()
				low_up.text = PersianText.reshaper("حداقل +")
				_style_button(low_up,false)
				_apply_font(low_up,16)
				low_up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				low_up.connect("pressed",self,"adjust_storage_rule",[id,"minimum",5])
				controls.add_child(low_up)
				var high_down = Button.new()
				high_down.text = PersianText.reshaper("حداکثر −")
				_style_button(high_down,false)
				_apply_font(high_down,16)
				high_down.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				high_down.connect("pressed",self,"adjust_storage_rule",[id,"maximum",-5])
				controls.add_child(high_down)
				var high_up = Button.new()
				high_up.text = PersianText.reshaper("حداکثر +")
				_style_button(high_up,false)
				_apply_font(high_up,16)
				high_up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				high_up.connect("pressed",self,"adjust_storage_rule",[id,"maximum",5])
				controls.add_child(high_up)
				_add_label("وقتی موجودی کم شد: "+("خرید از بازار" if str(rule.get("low_action","market")) == "market" else "افزایش تولید کارخانه"),15)
				_add_button("تغییر روش تأمین",self,"toggle_storage_low_action",[id])
				_add_label("وقتی موجودی زیاد شد: "+("فروش به بازار" if str(rule.get("high_action","market")) == "market" else "فروش از فروشگاه‌ها"),15)
				_add_button("تغییر روش فروش",self,"toggle_storage_high_action",[id])
				_add_button("اجرای تنظیمات همین ماده",self,"run_storage_rule",[id])
				active_section_container = null
			_add_label("ذخیره درختان جنگل: %d / ۱۰۰" % game.get_forest_tree_count())

		"report":
			_add_label("گزارش وقایع شهر", 22)
			var events = s.get("report_events", [])
			_add_label("جدیدترین رویدادها بالا نمایش داده می‌شوند | سقف ذخیره: ۱۰۰ پیام | تعداد فعلی: %d" % events.size(), 15)
			if events.empty():
				_add_label("هنوز رویدادی ثبت نشده است.", 18)
			else:
				for event_index in range(events.size() - 1, -1, -1):
					var event = events[event_index]
					var stamp = OS.get_datetime_from_unix_time(int(event.get("timestamp", 0)))
					var time_text = "%02d/%02d - %02d:%02d" % [int(stamp.get("day", 1)), int(stamp.get("month", 1)), int(stamp.get("hour", 0)), int(stamp.get("minute", 0))]
					_add_label("[%s] روز %d | %s" % [time_text, int(event.get("day", 1)), str(event.get("message", ""))], 17)

		"help":
			_add_label("❔ راهنمای کامل مینی زکا سیتی", 25)
			_add_label("اینجا هر زمان گیر کردی برگرد؛ از شروع بازی تا اقتصاد، ساختمان‌ها و رقابت شهرها را قدم‌به‌قدم توضیح داده‌ایم.", 17)
			_add_button("🏙️ برگشت به شهر من", self, "return_home_from_menu")
			_add_label("🚀 شروع سریع برای بازیکن تازه‌وارد", 21)
			_add_help_section("۱. اول مأموریت‌ها را انجام بده", "از دکمه مأموریت‌ها شروع کن. مأموریت‌های آموزشی به‌ترتیب خرید زمین، ساخت خانه، ساخت مزرعه، استخدام شهروند و توسعه خدمات را یاد می‌دهند. هر مأموریت را بخوان؛ اگر دکمه رفتن داشت، از همان برای رفتن مستقیم به بخش مربوط استفاده کن.", "missions")
			_add_help_section("۲. زمین و ساختمان بساز", "در ساختمان‌ها زمین تازه بخر و بعد ساختمان مناسب را انتخاب کن. قبل از ساخت، هزینه، زمان ساخت، ظرفیت و نیاز به نیروی کار را بررسی کن. همه ساختمان‌ها فوری آماده نمی‌شوند؛ پروژه‌های در حال ساخت و زمان باقی‌مانده بالای صفحه دیده می‌شود.", "buildings")
			_add_help_section("۳. شهروند و شغل را مدیریت کن", "خانه ظرفیت سکونت ایجاد می‌کند؛ اما برای تولید و درآمد، بعضی ساختمان‌ها به کارگر نیاز دارند. از بخش شهروندان تعداد شاغل، بیکار و وضعیت گروه‌های شهروندی را بررسی کن. بدون نیروی انسانی کافی، توسعه اقتصادی متوقف می‌شود.", "citizens")
			_add_label("💰 پول، درآمد و اقتصاد", 21)
			_add_help_section("خزانه و درآمد شهرداری", "در شهر من موجودی خزانه، ظرفیت خزانه، پول قفل‌شده و درآمد روزانه شهرداری را می‌بینی. درآمد شهرداری با درآمد کسب‌وکارهای خصوصی یکی نیست. ظرفیت خزانه محدود است؛ اگر پر شود ممکن است نتوانی جایزه یا درآمد تازه‌ای دریافت کنی. پول قفل‌شده را با پول آزاد اشتباه نگیر.", "home")
			_add_help_section("بانک، وام و امور مالی", "قبل از گرفتن وام، مبلغ دریافتی، بهره، زمان بازپرداخت و قسط را با درآمد پایدار شهر مقایسه کن. برای پرداخت هزینه‌های روزمره روی وام تکیه نکن؛ ابتدا درآمد و تولید منظم بساز.", "bank")
			_add_help_section("اقتصاد خصوصی و کسب‌وکارها", "کسب‌وکارها می‌توانند از فعالیت شهروندان و تقاضای شهر درآمد بسازند. تعداد ساختمان، نیروی کار، رضایت و دسترسی به کالا روی نتیجه اثر می‌گذارند. درآمد خصوصی را با مالیات و درآمد شهرداری جداگانه بررسی کن.", "private_economy")
			_add_help_section("بازار، تجارت و منابع", "در بازار می‌توانی کالا و منابع را بخری یا صادر کنی. قیمت خرید و فروش را مقایسه کن و همه ذخایر ضروری را نفروش؛ مواد اولیه برای زنجیره تولید و توسعه بعدی لازم می‌شوند. سفارش‌ها و محموله‌های در حال ارسال را پیگیری کن.", "commerce")
			_add_help_section("انبار و مدیریت موجودی", "انبار برای نگهداری منابع است. ظرفیت انبار محدود است؛ موجودی کالاها را بررسی کن و فضای کافی برای تولید بعدی نگه دار. اگر یک منبع کم است، زنجیره تولید وابسته به آن هم ممکن است متوقف شود.", "storage")
			_add_label("🏗️ توسعه، خدمات و زمان", 21)
			_add_help_section("خدمات شهری و رضایت", "آب، برق، خوراک، درمان، آموزش، امنیت، تفریح و بهداشت محیط نیازهای جداگانه‌اند. در شهر من میانگین پوشش خدمات را ببین و برای نیازهای ضعیف، ساختمان مناسب بساز. جمعیت بیشتر یعنی نیاز بیشتر به خدمات و زیرساخت.", "home")
			_add_help_section("شهرداری، زمین و محله‌ها", "در شهرداری زمین‌ها، مالیات، درخواست‌ها و پروژه‌های شهری را مدیریت کن. ظرفیت ساخت هر محله و سهمیه ساختمان‌ها محدود است؛ پیش از خرید یا ساخت، محدودیت همان محله را بررسی کن و برای خدمات ضروری جا نگه دار.", "municipality")
			_add_help_section("روز، شب و ساخت‌وساز", "هر روز بازی ۱۰ دقیقه زمان واقعی دارد؛ ۷ دقیقه روز و ۳ دقیقه شب است. پایان روز، درآمدها، هزینه‌ها، تولید و رویدادها محاسبه می‌شوند. هم‌زمان حداکثر دو پروژه ساخت فعال می‌توانی داشته باشی؛ زمان ساخت را از بالای صفحه دنبال کن.", "home")
			_add_help_section("جاده و ناوگان", "جاده و ناوگان برای جابه‌جایی و پشتیبانی تجارت کاربرد دارند و می‌توانند هزینه نگهداری داشته باشند. پیش از توسعه مسیرها، درآمد و توان پرداخت هزینه‌های نگهداری را بررسی کن.", "transport")
			_add_label("🎯 مأموریت‌ها و سرگرمی‌های بلندمدت", 21)
			_add_help_section("مأموریت‌های روزانه و هفتگی", "مأموریت‌های روزانه با گذر روز عوض می‌شوند و مأموریت هفتگی هدف بزرگ‌تری دارد. انجام مأموریت همیشه به معنی دریافت جایزه نیست؛ اگر دکمه دریافت جایزه نمایش داده شد، آن را بزن. علامت هدیه بالای دکمه مأموریت‌ها یعنی جایزه آماده دریافت داری.", "missions")
			_add_help_section("ورود روزانه و زنجیره ورود", "با ورود در روزهای مختلف، زنجیره ورودت را حفظ کن و هدیه روزانه را از شهر من دریافت کن. جایزه روزانه را باید دستی دریافت کنی؛ اگر ظرفیت خزانه پر باشد، ابتدا باید برای دریافت آن فضا ایجاد کنی.", "home")
			_add_help_section("شهرهای رقیب و رتبه‌بندی", "شهرهای همسایه در گذر روزها رشد می‌کنند. امتیاز توسعه شهر تو با امتیاز آن‌ها مقایسه می‌شود؛ برای بهتر شدن رتبه، جمعیت، سطح و توسعه شهر را بالا ببر. این رتبه‌بندی فعلاً در همین ذخیره بازی محاسبه می‌شود.", "progress")
			_add_help_section("رازهای مخفی", "گاهی با گذر روزها یک سرنخ پنهان پیدا می‌کنی. سرنخ و هدفش را در پیشرفت شهر بخوان. وقتی نوار پیشرفت به هدف رسید، جایزه را از همان صفحه دستی دریافت کن.", "progress")
			_add_help_section("پروژه‌های عظیم", "برج بزرگ، مرکز تجارت و فرودگاه پروژه‌های چندمرحله‌ای هستند. هر مرحله به سطح، جمعیت، ساختمان یا صادرات مشخص و هزینه جداگانه نیاز دارد. فقط یک پروژه عظیم را هم‌زمان می‌توانی پیش ببری؛ پیش از سرمایه‌گذاری، شرایط و موجودی آزاد خزانه را بررسی کن.", "progress")
			_add_help_section("اتفاقات شهر و تصمیم‌های مهم", "رویدادهای تصادفی و تصمیم‌های شورای شهر می‌توانند روی پول، رضایت، اعتبار و نیازهای شهر اثر بگذارند. متن هر گزینه و هزینه‌اش را با دقت بخوان؛ بعضی تصمیم‌ها رایگان نیستند و پیامد انتخاب‌ها متفاوت است.", "home")
			_add_help_section("درخواست شهروندان", "گاهی شهروندان برای ساخت یک خدمت یا زیرساخت درخواست می‌دهند. درخواست را بخوان، در صورت توان قبول کن و ساختمان پیشنهادی را بساز. پس از تکمیل شرط، پاداش درخواست را دریافت کن؛ درخواست را فقط وقتی قبول کن که امکان انجامش را داری.", "citizens")
			_add_help_section("افتخارات و رکوردهای شهر", "در صفحه پیشرفت شهر، دستاوردهای بازشده، رکوردهای شخصی، چالش هفتگی و پروژه‌های بلندمدت را دنبال کن. بعضی افتخارات فقط با رسیدن به سطح، جمعیت یا رکورد مشخص باز می‌شوند.", "progress")
			_add_label("🌙 وقتی از بازی خارج می‌شوی", 21)
			_add_help_section("درآمد و گزارش زمان غیبت", "وقتی برمی‌گردی، بازی حداکثر ۱۰ روز غیبت را محاسبه می‌کند. درآمد خالص مثبت جدا نگه داشته می‌شود و تا وقتی خودت دکمه دریافت را نزنی وارد خزانه نمی‌شود. اگر درآمدی باقی نمانده باشد، ممکن است هزینه‌ها درآمد را خنثی کرده باشند.", "home")
			_add_help_section("ذخیره، توقف و شروع دوباره", "از منو می‌توانی بازی را متوقف کنی، ذخیره کنی یا به شهر من برگردی. شروع دوباره شهر، پیشرفت شهر فعلی را پاک می‌کند؛ قبل از تأیید این گزینه مطمئن شو واقعاً شهر تازه می‌خواهی.", "home")
			_add_label("💡 چند نکته برای پیشرفت بهتر", 21)
			_add_label("• اول مأموریت‌های آموزشی را انجام بده تا مسیر بازی را یاد بگیری.", 16)
			_add_label("• قبل از خرج بزرگ، درآمد روزانه، پول آزاد و ظرفیت خزانه را بررسی کن.", 16)
			_add_label("• خانه بساز، اما خدمات و شغل متناسب با جمعیت را فراموش نکن.", 16)
			_add_label("• همه منابع را نفروش؛ برای تولید و ساخت‌وساز ذخیره نگه دار.", 16)
			_add_label("• قبل از قبول درخواست شهروند یا شروع پروژه عظیم، هزینه و شرط‌ها را بخوان.", 16)
			_add_label("• جایزه مأموریت، هدیه ورود و درآمد آفلاین را در صورت آماده بودن دستی دریافت کن.", 16)
			_add_label("• هر روز گزارش شهر، رویداد هفتگی و رتبه رقبا را بررسی کن.", 16)
			_add_button("🏙️ حالا برگردیم به شهر!", self, "return_home_from_menu")

		"progress":
			_add_label("🏗️ پروژه‌های بلندمدت شهر",23)
			_add_label("این هدف‌ها برای توسعه چندمرحله‌ای شهر هستند؛ پیشرفتشان ذخیره می‌شود و جایزه را فقط یک‌بار می‌توانی بگیری.",16)
			for project in game.get_long_term_projects():
				var project_done = int(project.progress) >= int(project.goal)
				_add_label(str(project.title),19)
				_add_label(str(project.description),16)
				_add_label("پیشرفت: %d از %d | پاداش: %d سکه + %d تجربه" % [int(project.progress),int(project.goal),int(project.reward),int(project.xp)],16)
				var project_bar = ProgressBar.new()
				project_bar.min_value = 0
				project_bar.max_value = max(1,int(project.goal))
				project_bar.value = int(project.progress)
				project_bar.percent_visible = false
				project_bar.rect_min_size = Vector2(0,12)
				content.add_child(project_bar)
				if bool(project.claimed):
					_add_label("✓ جایزه دریافت شده",15)
				elif project_done:
					_add_button("🎁 دریافت جایزه پروژه",self,"claim_long_term_project",[str(project.id)])
				else:
					_add_label("● در حال پیشرفت",15)

			_add_label("🏙️ رقابت با شهرهای همسایه",23)
			_add_label("شهرهای رقیب هر روز رشد می‌کنند؛ جایگاه تو با امتیاز واقعی توسعه شهر سنجیده می‌شود.",15)
			for rival_row in game.get_rival_standings():
				var rival_prefix = "👑 " if bool(rival_row.get("is_player",false)) else "🏘️ "
				_add_label("%sرتبه %d | %s | امتیاز %d | جمعیت %d | سطح %d" % [rival_prefix,int(rival_row.get("rank",0)),str(rival_row.get("name","")),int(rival_row.get("score",0)),int(rival_row.get("population",0)),int(rival_row.get("level",1))],16)
			_add_label("🔎 رازها و کشفیات مخفی",23)
			var mystery = game.get_mystery_status()
			if bool(mystery.get("active",false)):
				_add_label("کشف تازه: "+str(mystery.get("title","راز مخفی")),18)
				_add_label(str(mystery.get("clue","")),15)
				_add_label(str(mystery.get("objective","")),16)
				_add_label("پیشرفت: %d از %d | پاداش: %d سکه + %d تجربه" % [int(mystery.get("progress",0)),int(mystery.get("goal",1)),int(mystery.get("reward",0)),int(mystery.get("xp",0))],16)
				if int(mystery.get("progress",0)) >= int(mystery.get("goal",1)):
					_add_button("🗝️ باز کردن راز و دریافت جایزه",self,"claim_mystery_reward")
			else:
				_add_label("هنوز راز تازه‌ای پیدا نشده؛ با رشد شهر و گذر روزها سرنخ‌های جدید ظاهر می‌شوند.",15)
				_add_label("رازهای کشف‌شده: %d" % int(mystery.get("completed",0)),15)
			_add_label("🏛️ سازه‌های عظیم و پروژه‌های چندمرحله‌ای",23)
			var landmark_status = game.get_landmark_project_status()
			if bool(landmark_status.get("active",false)):
				var stage_data = landmark_status.get("stage_data",{})
				_add_label("پروژه فعال: %s | مرحله %d از %d" % [str(landmark_status.get("title","")),int(landmark_status.get("stage",1)),int(landmark_status.get("stage_total",1))],18)
				_add_label("مرحله: %s | هزینه: %d سکه" % [str(stage_data.get("title","")),int(stage_data.get("cost",0))],16)
				_add_label("شرایط: سطح %d، جمعیت %d، ساختمان کل %d" % [int(stage_data.get("level",1)),int(stage_data.get("population",0)),int(stage_data.get("buildings",0))],15)
				var stage_button = _add_button("🏗️ سرمایه‌گذاری و تکمیل این مرحله",self,"invest_landmark_stage")
				stage_button.disabled = not bool(landmark_status.get("requirements_met",false)) or game.get_available_money() < int(stage_data.get("cost",0))
			else:
				_add_label("فقط یک پروژه عظیم را هم‌زمان می‌توانی پیش ببری. هر سازه سه مرحله و شرط‌های مخصوص دارد.",15)
				for landmark in game.get_landmark_project_definitions():
					var completed_landmarks = landmark_status.get("completed",[])
					var is_completed_landmark = str(landmark.id) in completed_landmarks
					_add_label("%s | پاداش افتتاح: %d سکه + %d تجربه" % [str(landmark.title),int(landmark.reward),int(landmark.xp)],17)
					_add_label(str(landmark.description),14)
					if is_completed_landmark:
						_add_label("✓ در شهر افتتاح شده",15)
					else:
						_add_button("آغاز پروژه "+str(landmark.title),self,"start_landmark_project",[str(landmark.id)])

			_add_label("🏆 افتخارات و رکوردهای شهر",23)
			var league = game.get_city_league()
			_add_label("رتبه شهر: %s | امتیاز توسعه: %d" % [str(league.name),int(league.score)],19)
			if int(league.next) > 0:
				_add_label("برای رتبه بعدی به %d امتیاز نیاز داری." % max(0,int(league.next)-int(league.score)),15)
			_add_label("این رتبه‌بندی بر اساس ذخیره همین شهر محاسبه می‌شود؛ جدول جهانی آنلاین نیست.",14)
			var weekly = game.get_weekly_challenge()
			_add_label("🏁 رقابت هفتگی | "+str(weekly.title),19)
			_add_label(str(weekly.description),15)
			_add_label("پیشرفت: %d از %d | جایزه: %d سکه + %d تجربه" % [int(weekly.progress),int(weekly.goal),int(weekly.reward),int(weekly.xp)],16)
			if bool(weekly.claimed):
				_add_label("✓ جایزه رقابت این هفته دریافت شده است.",15)
			elif int(weekly.progress) >= int(weekly.goal):
				_add_button("🏆 دریافت جایزه رقابت هفتگی",self,"claim_weekly_challenge")
			var records = game.get_city_records()
			_add_label("📊 بهترین رکوردها",19)
			_add_label("بیشترین جمعیت: %d نفر | بیشترین خزانه: %d سکه" % [int(records.get("peak_population",0)),int(records.get("peak_money",0))],16)
			_add_label("بالاترین سطح: %d | بیشترین رضایت: %d/۱۰۰ | بیشترین ساختمان: %d" % [int(records.get("peak_level",1)),int(records.get("peak_satisfaction",0)),int(records.get("most_buildings",0))],16)
			var achievement_list = game.get_achievements()
			var unlocked_achievements = 0
			for achievement in achievement_list:
				if bool(achievement.unlocked):
					unlocked_achievements += 1
			_add_label("نشان‌های بازشده: %d از %d" % [unlocked_achievements,achievement_list.size()],17)
			for achievement in achievement_list:
				var achievement_status = "🏅 دریافت‌شده" if bool(achievement.unlocked) else "🔒 قفل"
				_add_label(achievement_status+" | "+str(achievement.title),18)
				_add_label(str(achievement.description),15)
		"missions":
			_add_label("📅 مأموریت‌های روزانه", 23)
			_add_label("هر روز سه هدف تازه برای توسعه شهر؛ پیشرفت و جایزه‌ها جدا از مأموریت‌های اصلی ذخیره می‌شوند.", 16)
			for daily_mission in game.get_daily_missions():
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
				daily_card.add_stylebox_override("panel", daily_style)
				content.add_child(daily_card)
				var daily_body = VBoxContainer.new()
				daily_body.add_constant_override("separation", 5)
				daily_card.add_child(daily_body)
				var daily_title = Label.new()
				daily_title.text = PersianText.reshaper(str(daily_mission.title))
				daily_title.align = Label.ALIGN_RIGHT
				daily_title.autowrap = true
				_apply_font(daily_title, 18)
				daily_title.add_color_override("font_color", Color("#fde68a") if daily_done else Color("#ffffff"))
				daily_body.add_child(daily_title)
				var daily_desc = Label.new()
				daily_desc.text = PersianText.reshaper(str(daily_mission.description))
				daily_desc.align = Label.ALIGN_RIGHT
				daily_desc.autowrap = true
				_apply_font(daily_desc, 16)
				daily_desc.add_color_override("font_color", Color("#dbeafe"))
				daily_body.add_child(daily_desc)
				var daily_progress = Label.new()
				daily_progress.text = PersianText.reshaper("پیشرفت: %d از %d  |  جایزه: %d سکه + %d تجربه" % [int(daily_mission.progress), int(daily_mission.goal), int(daily_mission.reward), int(daily_mission.xp)])
				daily_progress.align = Label.ALIGN_RIGHT
				daily_progress.autowrap = true
				_apply_font(daily_progress, 15)
				daily_body.add_child(daily_progress)
				if bool(daily_mission.claimed):
					var daily_status = Label.new()
					daily_status.text = PersianText.reshaper("✓ جایزه امروز دریافت شده")
					daily_status.align = Label.ALIGN_RIGHT
					_apply_font(daily_status, 16)
					daily_status.add_color_override("font_color", Color("#86efac"))
					daily_body.add_child(daily_status)
				elif daily_done:
					_add_daily_claim_button(daily_body, str(daily_mission.id))
				else:
					var daily_waiting = Label.new()
					daily_waiting.text = PersianText.reshaper("● در حال انجام")
					daily_waiting.align = Label.ALIGN_RIGHT
					_apply_font(daily_waiting, 15)
					daily_waiting.add_color_override("font_color", Color("#cbd5e1"))
					daily_body.add_child(daily_waiting)
			_add_label("━━━━━━━━━━━━━━━━━━━━", 14)
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
			_add_label("🎯 مأموریت‌های شهر", 23)
			_add_label("اصلی: آموزش مرحله‌به‌مرحله | فرعی: کسب پول و تجربه بیشتر", 16)
			_add_label("آموزش اصلی: %d از %d | مأموریت فرعی: %d از %d" % [main_claimed,main_total,side_claimed,side_total],18)
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
			summary_panel.add_stylebox_override("panel", summary_style)
			summary_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content.add_child(summary_panel)
			var summary_label = Label.new()
			summary_label.text = PersianText.reshaper("پیشرفت کلی مأموریت‌ها: %d از %d" % [main_claimed + side_claimed, main_total + side_total])
			summary_label.align = Label.ALIGN_CENTER
			summary_label.autowrap = true
			summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_apply_font(summary_label, 19)
			summary_label.add_color_override("font_color", Color("#ffffff"))
			summary_panel.add_child(summary_label)
			var visible_missions = 0
			var last_mission_type = ""
			for mission_index in range(mission_list.size()):
				var mission = mission_list[mission_index]
				var definition = {}
				for item in game.MISSION_DEFINITIONS:
					if str(item.id) == str(mission.get("id", "")):
						definition = item
						break
				if definition.empty():
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
				visible_missions += 1
				var mission_type = "legacy" if is_legacy_mission else str(definition.get("type","main"))
				if mission_type != last_mission_type:
					last_mission_type = mission_type
					if mission_type == "legacy":
						_add_label("🎁 پاداش‌های باقی‌مانده از نسخه قبلی", 21)
						_add_label("اگر در نسخه قبلی مأموریتی را کامل کرده بودی اما جایزه‌اش را نگرفته بودی، اینجا هنوز قابل دریافت است.",15)
					elif mission_type == "main":
						_add_label("📘 مأموریت‌های اصلی | آموزش بازی", 21)
						_add_label("این مسیر را به‌ترتیب پیش ببر؛ هر مرحله بخش تازه‌ای از مدیریت شهر را آموزش می‌دهد.",15)
					else:
						_add_label("⭐ ادامه مسیر مأموریت‌ها | پول و تجربه", 21)
						_add_label("این مأموریت‌ها به‌ترتیب باز می‌شوند؛ با دریافت جایزه هر مرحله، هدف بعدی فعال می‌شود.",15)
				var is_claimed = bool(mission.get("claimed", false))
				var is_completed = bool(mission.get("completed", false))
				var card = PanelContainer.new()
				card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				card.rect_min_size = Vector2(0, 0)
				card.rect_clip_content = false
				var card_style = StyleBoxFlat.new()
				card_style.bg_color = Color("#173b32") if is_claimed else (Color("#493719") if is_completed else Color("#202b3b"))
				card_style.border_color = Color("#4ade80") if is_claimed else (Color("#fbbf24") if is_completed else Color("#64748b"))
				card_style.set_border_width_all(2)
				card_style.set_corner_radius_all(12)
				card_style.content_margin_left = 0
				card_style.content_margin_right = 0
				card_style.content_margin_top = 0
				card_style.content_margin_bottom = 0
				card.add_stylebox_override("panel", card_style)
				content.add_child(card)
				var card_margin = MarginContainer.new()
				card_margin.add_constant_override("margin_left", 14)
				card_margin.add_constant_override("margin_right", 14)
				card_margin.add_constant_override("margin_top", 12)
				card_margin.add_constant_override("margin_bottom", 12)
				card_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				card.add_child(card_margin)
				var card_body = VBoxContainer.new()
				card_body.add_constant_override("separation", 7)
				card_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				card_body.rect_clip_content = false
				card_margin.add_child(card_body)
				var is_unlocked = bool(mission.get("unlocked", false))
				var status_text = "✓ جایزه دریافت شده" if is_claimed else ("🎁 جایزه آماده دریافت" if is_completed else ("● در حال انجام" if is_unlocked else "🔒 پس از تکمیل مرحله قبلی باز می‌شود"))
				var title_row = HBoxContainer.new()
				title_row.add_constant_override("separation", 8)
				card_body.add_child(title_row)
				var title_label = Label.new()
				title_label.text = PersianText.reshaper(str(definition.title))
				title_label.align = Label.ALIGN_RIGHT
				title_label.clip_text = false
				title_label.autowrap = true
				title_label.rect_min_size = Vector2(0, 34)
				title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				_apply_font(title_label, 19)
				title_label.add_color_override("font_color", Color("#86efac") if is_claimed else (Color("#fde68a") if is_completed else Color("#ffffff")))
				title_row.add_child(title_label)
				var status_label = Label.new()
				status_label.text = PersianText.reshaper(status_text)
				status_label.align = Label.ALIGN_RIGHT
				status_label.autowrap = true
				status_label.clip_text = false
				status_label.rect_min_size = Vector2(0, 30)
				status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				_apply_font(status_label, 16)
				status_label.add_color_override("font_color", Color("#86efac") if is_claimed else (Color("#fde68a") if is_completed else Color("#cbd5e1")))
				card_body.add_child(status_label)
				var description_label = Label.new()
				description_label.text = PersianText.reshaper(str(definition.description))
				description_label.align = Label.ALIGN_RIGHT
				description_label.autowrap = true
				description_label.clip_text = false
				description_label.rect_min_size = Vector2(0, 48)
				description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				_apply_font(description_label, 17)
				description_label.add_color_override("font_color", Color("#f8fafc"))
				card_body.add_child(description_label)
				var current_progress = int(mission.get("progress", 0))
				var target_progress = max(1, int(definition.goal))
				var progress_label = Label.new()
				progress_label.text = PersianText.reshaper("پیشرفت: %d از %d     |     پاداش: %d سکه + %d تجربه" % [current_progress, target_progress, int(definition.reward), int(definition.get("xp",0))])
				progress_label.align = Label.ALIGN_RIGHT
				progress_label.autowrap = true
				progress_label.clip_text = false
				progress_label.rect_min_size = Vector2(0, 34)
				progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				_apply_font(progress_label, 16)
				progress_label.add_color_override("font_color", Color("#bae6fd"))
				card_body.add_child(progress_label)
				var mission_progress = ProgressBar.new()
				mission_progress.min_value = 0
				mission_progress.max_value = target_progress
				mission_progress.value = min(current_progress, target_progress)
				mission_progress.percent_visible = false
				mission_progress.rect_min_size = Vector2(0, 12)
				var mission_fill = StyleBoxFlat.new()
				mission_fill.bg_color = Color("#22c55e") if is_completed else Color("#38bdf8")
				mission_fill.set_corner_radius_all(6)
				mission_progress.add_stylebox_override("fg", mission_fill)
				var mission_bg = StyleBoxFlat.new()
				mission_bg.bg_color = Color("#334155")
				mission_bg.set_corner_radius_all(6)
				mission_progress.add_stylebox_override("bg", mission_bg)
				card_body.add_child(mission_progress)
				if not is_claimed:
					var hint_label = Label.new()
					hint_label.text = PersianText.reshaper("راهنما: " + str(definition.get("hint", "از بخش‌های شهر هدف را دنبال کن.")))
					hint_label.align = Label.ALIGN_RIGHT
					hint_label.autowrap = true
					hint_label.clip_text = false
					hint_label.rect_min_size = Vector2(0, 48)
					hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					_apply_font(hint_label, 16)
					hint_label.add_color_override("font_color", Color("#cbd5e1"))
					card_body.add_child(hint_label)
				var go_button = Button.new()
				go_button.text = PersianText.reshaper("رفتن به بخش مربوط به این مأموریت  ←")
				go_button.rect_min_size = Vector2(0, 58 if get_viewport_rect().size.x < 900 else 50)
				go_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				_apply_font(go_button, 19 if get_viewport_rect().size.x < 900 else 17)
				_style_button(go_button, false)
				go_button.connect("pressed", self, "go_to_mission_target", [str(mission.get("id", ""))])
				card_body.add_child(go_button)
				if is_unlocked and is_completed and not is_claimed:
					var claim_button = Button.new()
					claim_button.text = PersianText.reshaper("🎁 دریافت جایزه و باز کردن مرحله بعد")
					claim_button.rect_min_size = Vector2(0, 58 if get_viewport_rect().size.x < 900 else 50)
					claim_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					_apply_font(claim_button, 18)
					_style_button(claim_button, false)
					claim_button.connect("pressed", self, "claim_mission", [mission_index])
					card_body.add_child(claim_button)
			if visible_missions == 0:
				_add_label("آموزش هنوز شروع نشده است؛ بازی را ادامه بده.", 17)
		_:
			_add_label("بخش پیدا نشد.")
	# Extra scrollable safe area so the last controls/text stay above Android browser navigation bars.
	var bottom_scroll_space = Control.new()
	bottom_scroll_space.rect_min_size = Vector2(0, 180 if get_viewport_rect().size.x < 900 else 90)
	bottom_scroll_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(bottom_scroll_space)
	header_label.text = PersianText.reshaper("مینی زکا سیتی  |  خزانه: %d  |  جمعیت: %d" % [s.money,s.population])

func _municipality_section(title, section_id):
	var expanded = bool(municipality_section_expanded.get(section_id, false))
	var header = _add_button(("▼ " if expanded else "▶ ") + title, self, "toggle_municipality_section", [section_id])
	active_section_container = VBoxContainer.new()
	active_section_container.add_constant_override("separation", 5)
	active_section_container.visible = expanded
	content.add_child(active_section_container)

func _end_municipality_section():
	active_section_container = null

func toggle_citizen_status_group(group_name):
	var key = str(group_name)
	citizen_status_expanded[key] = not bool(citizen_status_expanded.get(key,false))
	show_page("citizens")

func toggle_municipality_section(section_id):
	var key = str(section_id)
	municipality_section_expanded[key] = not bool(municipality_section_expanded.get(key, false))
	show_page("municipality")

func _add_home_services_panel(city_state):
	var compact = get_viewport_rect().size.x < 900
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
	panel.add_stylebox_override("panel", panel_style)
	content.add_child(panel)
	var body = VBoxContainer.new()
	body.add_constant_override("separation", 9)
	panel.add_child(body)

	var total_coverage = 0
	var service_count = game.SERVICE_GROUPS.size()
	for service_id in game.SERVICE_GROUPS.keys():
		total_coverage += int(city_state.get("services", {}).get(service_id, 0))
	var average_coverage = int(round(float(total_coverage) / float(max(1, service_count))))
	var header = Button.new()
	header.text = PersianText.reshaper(("%s  🏙️  خدمات و زیرساخت شهر" % ("▼" if home_city_details_expanded else "▶")) + "     میانگین پوشش: %d%%" % average_coverage)
	header.rect_min_size = Vector2(0, 62 if compact else 54)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.align = Button.ALIGN_RIGHT
	_apply_font(header, 19 if compact else 17)
	_style_button(header, false)
	header.connect("pressed", self, "toggle_home_city_details")
	body.add_child(header)

	var hint = Label.new()
	hint.text = PersianText.reshaper("وضعیت آب، برق، درمان، امنیت و امکانات شهر را یک‌جا ببین.")
	hint.align = Label.ALIGN_RIGHT
	hint.autowrap = true
	_apply_font(hint, 15 if compact else 14)
	hint.add_color_override("font_color", Color("#cbd5e1"))
	body.add_child(hint)

	if not home_city_details_expanded:
		return

	var section_line = HSeparator.new()
	body.add_child(section_line)
	var section_title = Label.new()
	section_title.text = PersianText.reshaper("شاخص خدمات شهری")
	section_title.align = Label.ALIGN_RIGHT
	_apply_font(section_title, 18)
	section_title.add_color_override("font_color", Color("#f8fafc"))
	body.add_child(section_title)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_constant_override("hseparation", 8)
	grid.add_constant_override("vseparation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(grid)
	var service_order = ["food","water","power","health","education","safety","leisure","sanitation"]
	for service_id in service_order:
		if not game.SERVICE_GROUPS.has(service_id):
			continue
		var service_data = game.SERVICE_GROUPS[service_id]
		var coverage = int(clamp(int(city_state.get("services", {}).get(service_id, 0)), 0, 100))
		var need = int(clamp(int(city_state.get("needs", {}).get(service_id, 60)), 0, 100))
		var building_total = 0
		for building_id in service_data.get("buildings", []):
			building_total += game.get_building_count(str(building_id))
		_add_service_metric_card(grid, str(service_data.get("name", service_id)), coverage, need, building_total, compact)

	var infra_title = Label.new()
	infra_title.text = PersianText.reshaper("زیرساخت‌های پشتیبان")
	infra_title.align = Label.ALIGN_RIGHT
	_apply_font(infra_title, 18)
	infra_title.add_color_override("font_color", Color("#f8fafc"))
	body.add_child(infra_title)
	var central_bank_status = "فعال" if game.has_central_bank() else ("بازسازی: %d روز" % int(city_state.get("central_bank_rebuild_days_left", 0)) if int(city_state.get("central_bank_rebuild_days_left", 0)) > 0 else "ساخته نشده")
	var infrastructure_text = "ساختمان‌ها: %d   |   ظرفیت انبار: %d\nبانک مرکزی: %s   |   بانک شهری: %d\nجنگل: %d/۱۰۰ درخت   |   معادن فعال: %d" % [city_state.buildings.size(), game.get_storage_capacity(), central_bank_status, game.get_building_count("municipal_bank"), game.get_forest_tree_count(), _active_mine_count()]
	var infra_label = Label.new()
	infra_label.text = PersianText.reshaper(infrastructure_text)
	infra_label.align = Label.ALIGN_RIGHT
	infra_label.autowrap = true
	infra_label.rect_min_size = Vector2(0, 76 if compact else 64)
	_apply_font(infra_label, 16 if compact else 15)
	infra_label.add_color_override("font_color", Color("#dbeafe"))
	body.add_child(infra_label)

func _add_service_metric_card(parent, title_text, coverage, need, building_count, compact):
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
	card.add_stylebox_override("panel", card_style)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var stack = VBoxContainer.new()
	stack.add_constant_override("separation", 4)
	card.add_child(stack)

	var title = Label.new()
	title.text = PersianText.reshaper("%s  (%d ساختمان)" % [title_text, building_count])
	title.align = Label.ALIGN_RIGHT
	title.autowrap = true
	title.rect_min_size = Vector2(0, 38 if compact else 32)
	_apply_font(title, 16 if compact else 15)
	title.add_color_override("font_color", Color("#f8fafc"))
	stack.add_child(title)

	var coverage_label = Label.new()
	coverage_label.text = PersianText.reshaper("پوشش خدمات: %d٪" % coverage)
	coverage_label.align = Label.ALIGN_RIGHT
	_apply_font(coverage_label, 15)
	coverage_label.add_color_override("font_color", Color("#86efac") if coverage >= 70 else (Color("#fcd34d") if coverage >= 40 else Color("#fca5a5")))
	stack.add_child(coverage_label)

	var coverage_bar = ProgressBar.new()
	coverage_bar.min_value = 0
	coverage_bar.max_value = 100
	coverage_bar.value = coverage
	coverage_bar.percent_visible = false
	coverage_bar.rect_min_size = Vector2(0, 9)
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color("#22c55e") if coverage >= 70 else (Color("#f59e0b") if coverage >= 40 else Color("#ef4444"))
	fill.set_corner_radius_all(4)
	coverage_bar.add_stylebox_override("fg", fill)
	var track = StyleBoxFlat.new()
	track.bg_color = Color("#334155")
	track.set_corner_radius_all(4)
	coverage_bar.add_stylebox_override("bg", track)
	stack.add_child(coverage_bar)

	var need_label = Label.new()
	need_label.text = PersianText.reshaper("رضایت از این نیاز: %d٪" % need)
	need_label.align = Label.ALIGN_RIGHT
	_apply_font(need_label, 14)
	need_label.add_color_override("font_color", Color("#cbd5e1"))
	stack.add_child(need_label)

func _service_summary():
	var parts = []
	for id in game.SERVICE_GROUPS.keys():
		var label = str(game.SERVICE_GROUPS[id].name)
		parts.append("%s %d%%" % [label, int(game.state.get("services",{}).get(id,0))])
	return " | ".join(parts)

func _needs_summary():
	var labels = {"food":"خوراک","water":"آب","power":"برق","health":"سلامت","education":"آموزش","safety":"امنیت","leisure":"تفریح","sanitation":"بهداشت"}
	var parts = []
	for id in labels.keys():
		parts.append("%s %d%%" % [labels[id], int(game.state.get("needs",{}).get(id,60))])
	return " | ".join(parts)

func _active_mine_count():
	var count = 0
	for mine in game.get_mines():
		if bool(mine.get("active", false)):
			count += 1
	return count

func _sort_building_ids_by_unlock_priority(a, b):
	var definitions = game.get_building_definitions()
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

func _add_building_category_items(category):
	var visible_buildings = 0
	var definitions = game.get_building_definitions()
	var building_ids = []
	for id in definitions.keys():
		var data = definitions[id]
		if category == "همه" and str(data.get("category","")) == "حمل‌ونقل":
			continue
		if category == "ماهیگیری" and not str(id) in ["fish_lake","fishing_dock","fish_market","fish_processing_plant"]:
			continue
		if category != "همه" and category != "ماهیگیری" and str(data.get("category","")) != category:
			continue
		building_ids.append(str(id))
	building_ids.sort_custom(self, "_sort_building_ids_by_unlock_priority")
	for id in building_ids:
		var data = definitions[id]
		visible_buildings += 1
		var s = game.state
		var population_unlocked = int(s.population) >= int(data.get("unlock", 0))
		var required_level = int(data.get("level_unlock", 1))
		var level_unlocked = int(s.level) >= required_level
		var unlocked = population_unlocked and level_unlocked
		var label = "%s | هزینه: %d | زمین: %d قطعه | جمعیت: %d | سطح: %d" % [data.name,data.cost,game.get_land_size(id),data.unlock,required_level]
		if not level_unlocked:
			label += " | 🔒 قفل سطح"
		var building_button = _add_button(label, self, "build_building", [id])
		building_button.disabled = not level_unlocked
	if visible_buildings == 0:
		_add_label("در این دسته ساختمانی تعریف نشده است.", 16)

func select_building_category(category):
	var requested = str(category)
	selected_building_category = "" if selected_building_category == requested else requested
	show_page("buildings")

func refill_mine(index):
	var result = game.refill_iron_mine(index)
	show_page("buildings")
	_show_message(result.message)

func _resource_summary():
	var parts = []
	for id in game.get_resource_definitions().keys():
		parts.append("%s: %d" % [game.get_resource_definitions()[id].name,game.state.resources.get(id,0)])
	return " | ".join(parts)


func resolve_civic_request(request_id, approved):
	var result = game.resolve_civic_request(request_id, approved)
	show_page("municipality")
	_show_message(result.message)

func resolve_private_request(request_id, approved):
	var result = game.resolve_civic_request(request_id, approved)
	show_page("private_economy")
	_show_message(result.message)

func adjust_business_tax(delta):
	var result = game.adjust_business_tax(delta)
	show_page("municipality")
	_show_message(result.message)

func adjust_business_permit_fee(delta):
	var result = game.adjust_business_permit_fee(delta)
	show_page("municipality")
	_show_message(result.message)

func adjust_private_land_price(delta):
	var result = game.adjust_private_land_price(delta)
	show_page("municipality")
	_show_message(result.message)

func request_bank_loan(amount, days):
	var result = game.take_bank_loan(int(amount),int(days))
	show_page("bank")
	_show_message(result.message)

func repay_bank_loan_manual(index):
	var result = game.repay_bank_loan_manual(int(index))
	show_page("bank")
	_show_message(result.message)

func repay_bank_loan(index):
	var result = game.repay_bank_loan_early(int(index))
	show_page("bank")
	_show_message(result.message)

func open_bank_deposit(amount, days):
	var result = game.create_bank_deposit(int(amount),int(days))
	show_page("bank")
	_show_message(result.message)

func withdraw_bank_savings(index):
	var result = game.withdraw_bank_deposit(int(index))
	show_page("bank")
	_show_message(result.message)

func buy_land():
	var result = game.buy_land(1)
	show_page("buildings")
	_show_message(result.message)

func build_building(id):
	var result = game.build(id)
	show_page("buildings")
	_show_message(result.message)

func collect_profit(index):
	var result = game.collect_business_profit(index)
	show_page("buildings")
	_show_message(result.message)

func toggle_home_city_details():
	home_city_details_expanded = not home_city_details_expanded
	show_page("home")

func toggle_home_buildings():
	home_buildings_expanded = not home_buildings_expanded
	show_page("home")

func toggle_home_economy():
	home_economy_expanded = not home_economy_expanded
	show_page("home")

func toggle_demolish_panel():
	demolish_panel_expanded = not demolish_panel_expanded
	show_page("home")

func select_home_building(id):
	selected_home_building_id = str(id)
	demolish_panel_expanded = true
	selected_demolish_quantity = 1
	show_page("home")

func adjust_demolish_quantity(delta):
	if selected_home_building_id == "":
		return
	var available = game.get_building_count(selected_home_building_id)
	selected_demolish_quantity = int(clamp(selected_demolish_quantity + int(delta), 1, max(1,available)))
	show_page("home")

func demolish_selected_buildings():
	if selected_home_building_id == "":
		return
	var remaining_to_remove = min(selected_demolish_quantity, game.get_building_count(selected_home_building_id))
	var removed = 0
	for i in range(game.state.buildings.size() - 1, -1, -1):
		if remaining_to_remove <= 0:
			break
		if str(game.state.buildings[i].get("id","")) != selected_home_building_id:
			continue
		var result = game.demolish(i)
		if bool(result.get("ok",false)):
			removed += 1
			remaining_to_remove -= 1
		else:
			_show_message(result.message)
			break
	if game.get_building_count(selected_home_building_id) <= 0:
		selected_home_building_id = ""
	selected_demolish_quantity = 1
	show_page("home")
	_show_message("%d ساختمان تخریب شد." % removed if removed > 0 else "ساختمانی تخریب نشد.")

func demolish_building(index):
	var result = game.demolish(index)
	show_page("buildings")
	_show_message(result.message)

func set_recruitment_mode(mode):
	var result = game.set_citizen_recruitment_mode(mode)
	show_page("citizens")
	_show_message(result.message)

func accept_citizen_request(index):
	var result = game.accept_citizen_request(index)
	show_page("citizens")
	_show_message(result.message)

func reject_citizen_request(index):
	var result = game.reject_citizen_request(index)
	show_page("citizens")
	_show_message(result.message)

func reassign_jobs():
	game.assign_jobs()
	game.save_game()
	show_page("citizens")
	_show_message("تخصیص شغل‌ها به‌روزرسانی شد.")

func upgrade_road():
	var result = game.upgrade_roads()
	show_page("transport")
	_show_message(result.message)

func build_transport_facility(building_id):
	var result = game.build(str(building_id))
	show_page("transport")
	_show_message(result.message)

func advance_day():
	var report = game.end_day()
	game.state["clock_last_unix"] = OS.get_unix_time()
	clock_cycle_seconds = 0.0
	game.state["clock_cycle_seconds"] = 0
	show_page("home")
	_show_message(report)

func import_from_city(city_id, resource_id, amount):
	var result = game.order_import(city_id, resource_id, amount)
	show_page("commerce")
	_show_message(result.message)

func make_import_contract(city_id, resource_id, amount, days):
	var result = game.create_import_contract(city_id, resource_id, amount, days)
	show_page("imports")
	_show_message(result.message)

func cancel_import(index):
	var result = game.cancel_import_contract(index)
	show_page("imports")
	_show_message(result.message)

func export_to_city(city_id, resource_id, amount):
	var result = game.trade_with_city(city_id, resource_id, amount)
	show_page("commerce")
	_show_message(result.message)

func buy_item(id, amount):
	var result = game.buy_resource(id, amount)
	show_page("commerce")
	_show_message(result.message)

func sell_item(id, amount):
	var result = game.sell_resource(id, amount)
	show_page("market")
	_show_message(result.message)


func toggle_current_district(district_id):
	var key = str(district_id)
	current_district_expanded[key] = not bool(current_district_expanded.get(key, false))
	show_page("buildings")

func toggle_storage_section(resource_id):
	var key = str(resource_id)
	storage_section_expanded[key] = not bool(storage_section_expanded.get(key, false))
	show_page("storage")

func adjust_storage_rule(resource_id, field, delta):
	var rule = game.get_storage_rule(str(resource_id))
	var value = max(0, int(rule.get(str(field), 0)) + int(delta))
	var result = game.set_storage_rule(str(resource_id), str(field), value)
	show_page("storage")
	_show_message(result.message)

func toggle_storage_low_action(resource_id):
	var result = game.toggle_storage_action(str(resource_id), "low")
	show_page("storage")
	_show_message(result.message)

func toggle_storage_high_action(resource_id):
	var result = game.toggle_storage_action(str(resource_id), "high")
	show_page("storage")
	_show_message(result.message)

func run_storage_rule(resource_id):
	var result = game.apply_storage_rule(str(resource_id), true)
	show_page("storage")
	_show_message(result.message)


func go_to_mission_target(mission_id):
	var target_page = "home"
	selected_building_category = ""
	match str(mission_id):
		"buy_land_tutorial", "build_house_tutorial":
			target_page = "buildings"
			selected_building_category = "خانه‌ها" if str(mission_id) == "build_house_tutorial" else ""
		"build_farm_tutorial", "side_fish_lake", "side_fishing_dock":
			target_page = "buildings"
			selected_building_category = "کشاورزی"
		"hire_worker_tutorial", "population_tutorial", "side_population":
			target_page = "citizens"
		"market_tutorial", "side_grocery", "side_bakery", "side_restaurant", "side_office", "side_fish_market":
			target_page = "buildings"
			selected_building_category = "کسب‌وکارها"
		"transport_tutorial":
			target_page = "transport"
		"level_tutorial", "main_level_five":
			target_page = "home"
		"main_city_bank", "main_central_bank", "side_reserve", "side_loan_paid", "side_bank":
			target_page = "bank"
		"side_private_tax":
			target_page = "private_economy"
		"side_export_eight":
			target_page = "transport"
		"side_collect_profit":
			target_page = "buildings"
			selected_building_category = "کسب‌وکارها"
		"side_positive_cashflow":
			target_page = "home"
		"side_high_satisfaction":
			target_page = "citizens"
		"side_expand_districts":
			target_page = "buildings"
		"main_storage":
			target_page = "storage"
		"main_water", "main_power", "main_school", "main_clinic", "side_water", "side_power", "side_school", "side_clinic", "side_sewage", "side_waste", "side_hospital", "side_police", "side_fire":
			target_page = "buildings"
			selected_building_category = "خدمات شهری"
		"main_wood", "main_sawmill", "main_carpenter", "side_wood", "side_sawmill", "side_carpenter", "side_fish_processing":
			target_page = "buildings"
			selected_building_category = "کارخانه‌ها"
		"main_stone", "side_stone_mine", "side_iron_mine":
			target_page = "buildings"
			selected_building_category = "معادن"
		"side_park", "side_playground", "side_sports", "side_cultural":
			target_page = "buildings"
			selected_building_category = "تفریح و فرهنگ"
		_:
			target_page = "home"
	show_page(target_page)
	if game_scroll_container != null and is_instance_valid(game_scroll_container):
		game_scroll_container.scroll_vertical = 0
	_show_message("به بخش مربوط به این مأموریت رفتی.")

func claim_login_reward():
	var result = game.claim_login_reward()
	show_page("home")
	_show_message(str(result.message))

func resolve_resident_request(request_id, accepted):
	var result = game.resolve_resident_request(int(request_id),bool(accepted))
	show_page("citizens")
	_show_message(str(result.message))

func go_to_resident_request_building(building_id):
	var definition = game.get_building_definitions().get(str(building_id),{})
	selected_building_category = str(definition.get("category","خدمات شهری"))
	show_page("buildings")
	_show_message("دسته ساختمان پیشنهادی شهروندان باز شد.")


func resolve_city_decision(option_id):
	var result = game.resolve_city_decision(str(option_id))
	show_page("home")
	_show_message(str(result.message))

func claim_mystery_reward():
	var result = game.claim_mystery_reward()
	show_page("progress")
	_show_message(str(result.message))

func start_landmark_project(project_id):
	var result = game.start_landmark_project(str(project_id))
	show_page("progress")
	_show_message(str(result.message))

func invest_landmark_stage():
	var result = game.invest_landmark_stage()
	show_page("progress")
	_show_message(str(result.message))

func claim_long_term_project(project_id):
	var result = game.claim_long_term_project(str(project_id))
	show_page("progress")
	_show_message(str(result.message))

func claim_weekly_challenge():
	var result = game.claim_weekly_challenge()
	show_page("progress")
	_show_message(str(result.message))

func _add_daily_claim_button(parent, mission_id):
	var claim_button = Button.new()
	claim_button.text = PersianText.reshaper("🎁 دریافت جایزه")
	claim_button.rect_min_size = Vector2(0, 48 if get_viewport_rect().size.x < 900 else 42)
	claim_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(claim_button, 17)
	_style_button(claim_button, false)
	claim_button.connect("pressed", self, "claim_daily_mission", [mission_id])
	parent.add_child(claim_button)

func claim_daily_mission(mission_id):
	var result = game.claim_daily_mission(str(mission_id))
	show_page("missions")
	_show_message(result.message)

func claim_mission(index):
	var result = game.claim_mission(index)
	show_page("missions")
	_show_message(result.message)

func save_now():
	var ok = game.save_game()
	_show_message("شهر ذخیره شد." if ok else "ذخیره‌سازی ناموفق بود.")