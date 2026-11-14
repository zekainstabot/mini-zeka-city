extends Control

const EngineScript = preload("res://scripts/GameEngine.gd")
const PersianText = preload("res://scripts/PersianText.gd")
const AudioManagerScript = preload("res://scripts/AudioManager.gd")
const MainUITheme = preload("res://scripts/MainUITheme.gd")
const HelpPageBuilder = preload("res://scripts/HelpPageBuilder.gd")
const AudioSettingsPage = preload("res://scripts/AudioSettingsPage.gd")
const CitizensPage = preload("res://scripts/CitizensPage.gd")
const CityReportPage = preload("res://scripts/CityReportPage.gd")
var game = null
var audio_manager = null
var last_audio_night_mode = false
var audio_warning_cooldown = 0.0
var current_page = "home"
var message_label = null
var content = null
var header_label = null
var brand_label = null
var city_name_overlay = null
var city_name_input = null
var city_name_setup_first_time = false
var ui_font = null
var level_status_bar = null
var xp_progress_bar = null
var level_status_label = null
var xp_progress_label = null
var selected_home_building_id = ""
var selected_building_category = ""
var selected_building_group = ""
var selected_demolish_quantity = 1
var demolish_panel_expanded = false
var home_buildings_expanded = false
var home_city_details_expanded = false
var home_economy_expanded = false
var clock_cycle_seconds = 0.0
var ambient_background = null
var ambient_background_color = Color("#172536")
var clock_label = null
var clock_save_accumulator = 0.0
var construction_check_accumulator = 0.0
var construction_time_labels = []
var game_paused = false
var menu_panel = null
var menu_overlay = null
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
var storage_production_expanded = false
var current_district_expanded = {}
var active_section_container = null
var mission_reward_badge = null
var mission_badge_refresh_timer = 0.0
var mission_target_building_id = ""
var mission_target_building_button = null
var last_activity_ticks = 0
var offline_summary_popup = null
var main_layout = null
var main_navigation_grid = null
var navigation_buttons = []
var menu_card = null
var exit_overlay = null
var last_layout_viewport_size = Vector2.ZERO
var last_device_back_ticks = 0
var help_overlay = null
var help_body = null
var help_previous_page = "home"
var help_scroll_original_index = 5

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
			last_activity_ticks = Time.get_ticks_msec()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE, KEY_BACK]:
		_handle_device_back()
		get_viewport().set_input_as_handled()
		return
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
				var horizontal_bar = game_scroll_container.get_h_scroll_bar()
				var max_horizontal = max(0.0, horizontal_bar.max_value - horizontal_bar.page)
				game_scroll_container.scroll_horizontal = int(clamp(float(game_scroll_container.scroll_horizontal) - delta_position.x * 1.25, 0.0, max_horizontal))
				horizontal_scroll_velocity = -delta_position.x * 13.0
			elif touch_scroll_axis == "vertical":
				var delta_y = event.position.y - touch_scroll_last_y
				var bar = game_scroll_container.get_v_scroll_bar()
				var max_scroll = max(0.0, bar.max_value - bar.page)
				game_scroll_container.scroll_vertical = int(clamp(float(game_scroll_container.scroll_vertical) - delta_y * 1.35, 0.0, max_scroll))
		touch_scroll_last_y = event.position.y
		touch_scroll_last_position = event.position

func _process(delta):
	_update_ambient_background(delta)
	if not touch_scroll_dragging and abs(horizontal_scroll_velocity) > 8.0 and game_scroll_container != null and is_instance_valid(game_scroll_container):
		var horizontal_bar = game_scroll_container.get_h_scroll_bar()
		var max_horizontal = max(0.0, horizontal_bar.max_value - horizontal_bar.page)
		game_scroll_container.scroll_horizontal = int(clamp(float(game_scroll_container.scroll_horizontal) + horizontal_scroll_velocity * delta, 0.0, max_horizontal))
		horizontal_scroll_velocity = lerp(horizontal_scroll_velocity, 0.0, min(1.0, delta * 7.5))
	else:
		horizontal_scroll_velocity = 0.0
	if game == null or game_paused:
		return
	if last_activity_ticks > 0 and Time.get_ticks_msec() - last_activity_ticks <= 90000:
		game.record_active_play_seconds(delta)
	var new_recruitment_count = game.process_citizen_recruitment_interval(delta)
	if new_recruitment_count > 0 and current_page == "citizens":
		show_page("citizens")
	clock_cycle_seconds += delta
	var audio_night_mode = clock_cycle_seconds >= 420.0
	if audio_manager != null and audio_night_mode != last_audio_night_mode:
		last_audio_night_mode = audio_night_mode
		audio_manager.set_night_mode(audio_night_mode)
	audio_warning_cooldown = max(0.0, audio_warning_cooldown - delta)
	_check_city_audio_warnings()
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
			audio_manager.play_sfx("construction_done")
			show_page(current_page)
			_show_message(str(game.state.get("last_report", "ساخت‌وساز تکمیل شد.")))
	if clock_cycle_seconds >= 600.0:
		clock_cycle_seconds -= 600.0
		var daily_audio_report = str(game.end_day())
		if daily_audio_report.find("رویداد") >= 0 or daily_audio_report.find("تصمیم") >= 0:
			audio_manager.play_sfx("event")
		game.state["clock_last_unix"] = Time.get_unix_time_from_system()
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
		var citizen_reports_changed = game.check_citizen_reports()
		if citizen_reports_changed and current_page == "report":
			show_page("report")
		game.state["clock_last_unix"] = Time.get_unix_time_from_system()
		game.state["clock_cycle_seconds"] = int(clock_cycle_seconds)
		game.save_game()

func _check_city_audio_warnings():
	if audio_manager == null or audio_warning_cooldown > 0.0 or not audio_manager.is_effects_enabled():
		return
	var money = int(game.state.get("money", 0))
	var needs = game.state.get("needs", {})
	var critical_need = false
	for need_id in ["food", "water", "power", "safety"]:
		if int(needs.get(need_id, 60)) <= 18:
			critical_need = true
			break
	if money <= 800 or critical_need:
		var safety_need = int(needs.get("safety", 60))
		if safety_need <= 12:
			audio_manager.play_sfx("siren")
		else:
			audio_manager.play_sfx("warning")
		audio_warning_cooldown = 90.0

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
	# Keep offline digest keys initialized even when no full offline day elapsed.
	game.state["pending_offline_digest"] = game.state.get("pending_offline_digest", [])
	var now = Time.get_unix_time_from_system()
	var last = int(game.state.get("clock_last_unix", now))
	var elapsed = max(0, now - last)
	# One in-game day of offline simulation equals one real hour.
	var elapsed_offline_days = int(floor(float(elapsed) / 3600.0))
	# Simulate at most ten days per return to keep catch-up processing bounded.
	var offline_days = min(10, elapsed_offline_days)
	var money_before = int(game.state.get("money", 0))
	if offline_days > 0:
		game.state["pending_offline_digest"] = []
	for day_index in range(offline_days):
		var offline_report = game.end_day(true)
		var digest = str(offline_report).split("\n")
		for digest_line in digest:
			var clean_line = str(digest_line).strip_edges()
			clean_line = clean_line.replace("نویدشهر", "یکی از شهرهای رقیب")
			if clean_line != "" and (clean_line.find("رویداد") >= 0 or clean_line.find("تصمیم") >= 0 or clean_line.find("رقبا") >= 0 or clean_line.find("درخواست") >= 0 or clean_line.find("تبریک") >= 0 or clean_line.find("تولید") >= 0):
				game.state["pending_offline_digest"].append(clean_line)
	while game.state["pending_offline_digest"].size() > 8:
		game.state["pending_offline_digest"].pop_front()
	var offline_net = int(game.state.get("money", money_before)) - money_before
	# Positive net earnings are held separately until the player explicitly collects them.
	if offline_net > 0:
		game.state["money"] = money_before
		game.state["pending_offline_income"] = int(game.state.get("pending_offline_income", 0)) + offline_net
	if elapsed_offline_days > 0:
		game.state["pending_offline_days"] = int(game.state.get("pending_offline_days", 0)) + elapsed_offline_days
	# Only request the welcome-back dialog after a single absence longer than
	# ten in-game days. Short visits/returns never trigger it.
	if elapsed_offline_days > 10:
		game.state["pending_offline_summary_ready"] = true
	game.state["clock_last_unix"] = now
	game.state["clock_cycle_seconds"] = int(game.state.get("clock_cycle_seconds", 0))
	game.save_game()

func _show_offline_summary():
	var days = int(game.state.get("pending_offline_days", 0))
	if days <= 0 or not bool(game.state.get("pending_offline_summary_ready", false)):
		return
	game.state["pending_offline_summary_ready"] = false
	game.save_game()

	var income = int(game.state.get("pending_offline_income", 0))
	var viewport_size = get_viewport_rect().size
	var compact = viewport_size.x < 700.0
	var popup_width = min(520.0, viewport_size.x - 28.0)

	# Keep only distinct, useful events from the offline report.
	var digest_items = game.state.get("pending_offline_digest", [])
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
	offline_summary_popup = overlay
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
	heading.text = PersianText.reshaper("خوش برگشتی به %s! 👋" % str(game.state.get("city_name", "شهرت")))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(heading, 21 if compact else 25)
	heading.add_theme_color_override("font_color", Color("#ffffff"))
	layout.add_child(heading)

	var intro = Label.new()
	intro.text = PersianText.reshaper("این مدت شهر تنها نبوده؛ ببین در غیابت چه خبر بوده.")
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(intro, 12 if compact else 14)
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
	days_label.text = PersianText.reshaper("%d روز دور از شهر" % days)
	days_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	days_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(days_label, 14 if compact else 17)
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
	income_label.text = PersianText.reshaper("%s سکه درآمد" % str(income))
	income_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	income_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(income_label, 14 if compact else 17)
	income_label.add_theme_color_override("font_color", Color("#86efac") if income > 0 else Color("#e2e8f0"))
	income_card.add_child(income_label)

	var news_title = Label.new()
	news_title.text = PersianText.reshaper("📌 اتفاقات مهم شهر")
	news_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_apply_font(news_title, 15 if compact else 17)
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
		calm.text = PersianText.reshaper("اتفاق ویژه‌ای ثبت نشده؛ شهر آرام بوده است.")
		calm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		calm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_apply_font(calm, 12 if compact else 14)
		calm.add_theme_color_override("font_color", Color("#cbd5e1"))
		news_list.add_child(calm)
	else:
		for index in range(min(unique_digest_items.size(), 8)):
			var event_label = Label.new()
			var event_text = str(unique_digest_items[index]).replace("نویدشهر", "یکی از شهرهای رقیب")
			event_label.text = PersianText.reshaper("• " + event_text)
			event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			event_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_apply_font(event_label, 12 if compact else 14)
			event_label.add_theme_color_override("font_color", Color("#e2e8f0"))
			news_list.add_child(event_label)

	if income > 0:
		var claim = Button.new()
		claim.text = PersianText.reshaper("واریز %s سکه به خزانه" % str(income))
		claim.custom_minimum_size = Vector2(0, 48 if compact else 52)
		claim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_font(claim, 14 if compact else 16)
		_style_button(claim, false)
		claim.pressed.connect(_claim_offline_income)
		layout.add_child(claim)

	var continue_button = Button.new()
	continue_button.text = PersianText.reshaper("ادامه بازی")
	continue_button.custom_minimum_size = Vector2(0, 44 if compact else 48)
	continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(continue_button, 14 if compact else 16)
	_style_button(continue_button, true)
	continue_button.pressed.connect(_close_offline_summary)
	layout.add_child(continue_button)

	add_child(overlay)

func _close_offline_summary():
	if offline_summary_popup != null and is_instance_valid(offline_summary_popup):
		offline_summary_popup.queue_free()
	offline_summary_popup = null
	show_page("home")

func _claim_offline_income():
	if offline_summary_popup != null and is_instance_valid(offline_summary_popup):
		offline_summary_popup.queue_free()
	offline_summary_popup = null
	var result = game.collect_offline_income()
	var message = str(result.get("message", "درآمد به خزانه واریز شد."))
	if int(game.state.get("pending_offline_income", 0)) <= 0:
		game.state["pending_offline_days"] = 0
		game.state["pending_offline_summary_ready"] = false
		game.save_game()
	show_page("home")
	_show_message(message)

func _notification(what):
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and game != null:
		_handle_device_back()
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST and game != null:
		game.state["clock_last_unix"] = Time.get_unix_time_from_system()
		game.state["clock_cycle_seconds"] = int(clock_cycle_seconds)
		game.save_game()

func _ready():
	# The entire interface is Persian, so make the root layout RTL and let
	# dynamically-created controls inherit the same direction.
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	_load_ui_font()
	audio_manager = AudioManagerScript.new()
	add_child(audio_manager)
	game = EngineScript.new()
	var has_existing_save = game.load_game()
	if not has_existing_save:
		game.new_game()
		# First launch starts in portrait. Later launches always use the
		# orientation saved by the player.
		game.state["screen_orientation"] = "portrait"
		game.save_game()
	var saved_orientation = str(game.state.get("screen_orientation", "portrait"))
	if saved_orientation not in ["auto", "portrait", "landscape"]:
		saved_orientation = "portrait"
		game.state["screen_orientation"] = saved_orientation
		game.save_game()
	_apply_screen_orientation(saved_orientation)
	game.register_login_today()
	game.get_daily_missions()
	game.get_weekly_challenge()
	last_activity_ticks = Time.get_ticks_msec()
	_apply_offline_progress()
	clock_cycle_seconds = float(game.state.get("clock_cycle_seconds", 0))
	last_audio_night_mode = clock_cycle_seconds >= 420.0
	audio_manager.set_night_mode(last_audio_night_mode)
	set_process(true)
	_build_ui()
	last_layout_viewport_size = Vector2.ZERO
	_apply_responsive_layout()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	show_page("home")
	if str(game.state.get("city_name", "")).strip_edges() == "":
		_open_city_name_setup(true)
	else:
		_show_offline_summary()



func _open_city_name_setup(first_time = false):
	city_name_setup_first_time = bool(first_time)
	if city_name_overlay != null and is_instance_valid(city_name_overlay):
		var old_layer = city_name_overlay.get_parent()
		if old_layer != null:
			old_layer.queue_free()
	var layer = CanvasLayer.new()
	layer.name = "CityNameSetupLayer"
	layer.layer = 120
	add_child(layer)
	city_name_overlay = Control.new()
	city_name_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	city_name_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(city_name_overlay)
	var shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.035, 0.065, 0.96)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	city_name_overlay.add_child(shade)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 18
	center.offset_right = -18
	center.offset_top = 18
	center.offset_bottom = -18
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	city_name_overlay.add_child(center)
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(min(520.0, get_viewport_rect().size.x - 36.0), 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#14243a")
	style.border_color = Color("#38bdf8")
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 26
	style.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", style)
	center.add_child(card)
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	card.add_child(layout)
	var title = Label.new()
	title.text = PersianText.reshaper("به شهر خودت خوش اومدی! 🏙️" if city_name_setup_first_time else "نام شهر رو تغییر بده")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(title, 23)
	title.add_theme_color_override("font_color", Color("#ffffff"))
	layout.add_child(title)
	var subtitle = Label.new()
	subtitle.text = PersianText.reshaper("برای شهرت یه اسم انتخاب کن؛ این اسم بالای شهر نمایش داده می‌شه." if city_name_setup_first_time else "اسم جدید شهر رو وارد کن.")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(subtitle, 15)
	subtitle.add_theme_color_override("font_color", Color("#cbd5e1"))
	layout.add_child(subtitle)
	city_name_input = LineEdit.new()
	city_name_input.text = str(game.state.get("city_name", ""))
	city_name_input.placeholder_text = "مثلاً: زکا‌آباد"
	city_name_input.max_length = 24
	city_name_input.custom_minimum_size = Vector2(0, 54)
	city_name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	city_name_input.clear_button_enabled = true
	_apply_font(city_name_input, 19)
	layout.add_child(city_name_input)
	if city_name_setup_first_time:
		var random_name_button = Button.new()
		random_name_button.text = PersianText.reshaper("🎲 انتخاب اسم تصادفی")
		random_name_button.custom_minimum_size = Vector2(0, 46)
		_apply_font(random_name_button, 16)
		_style_button(random_name_button, false)
		random_name_button.pressed.connect(_choose_random_city_name)
		layout.add_child(random_name_button)
	var save_button = Button.new()
	save_button.text = PersianText.reshaper("ساخت شهر من 🚀" if city_name_setup_first_time else "ذخیره نام جدید")
	save_button.custom_minimum_size = Vector2(0, 54)
	_apply_font(save_button, 18)
	_style_button(save_button, true)
	save_button.pressed.connect(_save_city_name)
	layout.add_child(save_button)
	if not city_name_setup_first_time:
		var cancel_button = Button.new()
		cancel_button.text = PersianText.reshaper("انصراف")
		cancel_button.custom_minimum_size = Vector2(0, 46)
		_apply_font(cancel_button, 16)
		_style_button(cancel_button, false)
		cancel_button.pressed.connect(_close_city_name_setup)
		layout.add_child(cancel_button)
	city_name_input.grab_focus()


func _choose_random_city_name():
	if game == null or city_name_input == null or not is_instance_valid(city_name_input):
		return
	# Selecting a suggested name must not save it immediately; let the player
	# review or edit it before confirming with the primary save button.
	city_name_input.text = game.get_random_city_name()


func _save_city_name():
	if city_name_input == null or not is_instance_valid(city_name_input):
		return
	var chosen_name = city_name_input.text.strip_edges()
	if chosen_name.is_empty():
		city_name_input.placeholder_text = "اول یه اسم برای شهرت بنویس"
		return
	chosen_name = chosen_name.substr(0, 24)
	game.state["city_name"] = chosen_name
	game.save_game()
	var was_first_time = city_name_setup_first_time
	_close_city_name_setup()
	show_page("home")
	if was_first_time:
		_show_message("شهر «%s» ساخته شد؛ خوش اومدی!" % chosen_name)
		_show_offline_summary()
	else:
		_show_message("نام شهر به «%s» تغییر کرد." % chosen_name)


func _close_city_name_setup():
	if city_name_overlay != null and is_instance_valid(city_name_overlay):
		var layer = city_name_overlay.get_parent()
		if layer != null:
			layer.queue_free()
	city_name_overlay = null
	city_name_input = null


func _on_viewport_size_changed():
	call_deferred("_apply_responsive_layout")

func _apply_responsive_layout():
	if main_layout == null or not is_instance_valid(main_layout):
		return
	var viewport_size = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	if viewport_size.is_equal_approx(last_layout_viewport_size):
		return
	var previous_scroll = 0
	if game_scroll_container != null and is_instance_valid(game_scroll_container):
		previous_scroll = game_scroll_container.scroll_vertical
	last_layout_viewport_size = viewport_size
	var compact = viewport_size.x < 900.0
	var narrow = viewport_size.x < 380.0
	main_layout.offset_left = 12 if narrow else (18 if compact else 24)
	main_layout.offset_right = -12 if narrow else (-18 if compact else -24)
	main_layout.offset_top = 8 if viewport_size.y < 500.0 else (12 if compact else 22)
	main_layout.offset_bottom = -8 if viewport_size.y < 500.0 else (12 if compact else -22)
	main_layout.add_theme_constant_override("separation", 8 if viewport_size.y < 500.0 else (12 if compact else 12))
	if main_navigation_grid != null and is_instance_valid(main_navigation_grid):
		# Keep three columns on wider landscape phones so navigation does not
		# consume most of the short screen; use two on portrait phones.
		main_navigation_grid.columns = 3 if viewport_size.x >= 650.0 and viewport_size.x > viewport_size.y else (1 if narrow else 2)
	for button in navigation_buttons:
		if button == null or not is_instance_valid(button):
			continue
		button.custom_minimum_size = Vector2(0, 48 if viewport_size.y < 500.0 else (58 if compact else 58))
		_apply_font(button, 15 if narrow else (16 if compact else 18))
	if menu_card != null and is_instance_valid(menu_card):
		menu_card.custom_minimum_size = Vector2(max(220.0, min(440.0, viewport_size.x - (24.0 if narrow else 40.0))), 0)
	if header_label != null and is_instance_valid(header_label):
		_apply_font(header_label, 22 if compact else 26)
	if game != null and content != null and is_instance_valid(content):
		show_page(current_page)
		if game_scroll_container != null and is_instance_valid(game_scroll_container):
			game_scroll_container.scroll_vertical = previous_scroll

func _get_ambient_background_target():
	# Muted colors keep the time-of-day atmosphere gentle and readable.
	var day_color = Color("#24394b")
	var dusk_color = Color("#3a3540")
	var night_color = Color("#151f31")
	var t = float(clock_cycle_seconds)
	if t < 30.0:
		return night_color.lerp(day_color, smoothstep(0.0, 30.0, t))
	if t < 360.0:
		return day_color
	if t < 420.0:
		return day_color.lerp(dusk_color, smoothstep(360.0, 420.0, t))
	if t < 570.0:
		return night_color
	return night_color.lerp(day_color, smoothstep(570.0, 600.0, t))

func _update_ambient_background(delta, immediate=false):
	if ambient_background == null or not is_instance_valid(ambient_background):
		return
	var target = _get_ambient_background_target()
	if immediate:
		ambient_background_color = target
	else:
		# Slow interpolation avoids abrupt flashes and distracting changes.
		ambient_background_color = ambient_background_color.lerp(target, clamp(float(delta) * 0.045, 0.0, 1.0))
	ambient_background.color = ambient_background_color

func _build_ui():
	ambient_background = ColorRect.new()
	ambient_background.name = "SoftDayNightBackground"
	ambient_background.color = Color("#172536")
	ambient_background.anchor_right = 1
	ambient_background.anchor_bottom = 1
	ambient_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ambient_background.z_index = -100
	add_child(ambient_background)
	_update_ambient_background(0.0, true)
	var root = VBoxContainer.new()
	main_layout = root
	root.name = "MainLayout"
	root.anchor_right = 1
	root.anchor_bottom = 1
	var screen_width = get_viewport_rect().size.x
	var compact_layout = screen_width < 900
	root.offset_left = 28 if compact_layout else 24
	root.offset_top = 16 if compact_layout else 22
	root.offset_right = -32 if compact_layout else -24
	root.offset_bottom = -16 if compact_layout else -22
	root.add_theme_constant_override("separation", 16 if compact_layout else 12)
	add_child(root)
	header_label = Label.new()
	header_label.text = PersianText.reshaper(str(game.state.get("city_name", "شهر من")))
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(header_label, 28 if compact_layout else 26)
	header_label.add_theme_color_override("font_color", Color("#ffffff"))
	root.add_child(header_label)
	brand_label = Label.new()
	brand_label.text = "✦  MINI ZEKA CITY  ✦"
	brand_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand_label.add_theme_color_override("font_color", Color("#7dd3fc"))
	brand_label.add_theme_color_override("font_shadow_color", Color("#0c4a6e"))
	brand_label.add_theme_constant_override("shadow_offset_x", 1)
	brand_label.add_theme_constant_override("shadow_offset_y", 1)
	_apply_font(brand_label, 12 if compact_layout else 14)
	root.add_child(brand_label)
	var menu_row = HBoxContainer.new()
	menu_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(menu_row)
	var menu_button = Button.new()
	menu_button.text = "☰"
	menu_button.tooltip_text = "باز کردن منوی بازی"
	menu_button.custom_minimum_size = Vector2(68 if compact_layout else 60, 62 if compact_layout else 52)
	menu_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_font(menu_button, 29 if compact_layout else 25)
	_style_button(menu_button, true)
	menu_row.add_child(menu_button)

	var help_button = Button.new()
	help_button.text = PersianText.reshaper("؟")
	help_button.tooltip_text = "راهنمای کامل بازی"
	help_button.custom_minimum_size = Vector2(58 if compact_layout else 50, 58 if compact_layout else 46)
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
	help_button.add_theme_stylebox_override("normal", help_normal)
	help_button.add_theme_stylebox_override("hover", help_hover)
	help_button.add_theme_stylebox_override("focus", help_hover)
	help_button.add_theme_stylebox_override("pressed", help_pressed)
	help_button.add_theme_color_override("font_color", Color("#ffffff"))
	help_button.add_theme_color_override("font_color_hover", Color("#ffffff"))
	help_button.add_theme_color_override("font_color_pressed", Color("#ffffff"))
	help_button.connect("pressed", Callable(self, "_open_help"))
	menu_row.add_child(help_button)
	# Full-screen modal menu dims the city and separates menu actions
	# from the navigation and city controls behind it.
	var menu_layer = CanvasLayer.new()
	menu_layer.layer = 50
	add_child(menu_layer)
	menu_overlay = ColorRect.new()
	menu_overlay.name = "GameMenuBackdrop"
	menu_overlay.color = Color(0.015, 0.035, 0.065, 0.82)
	menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_overlay.visible = false
	menu_layer.add_child(menu_overlay)
	# Help uses its own modal surface so the city navigation is fully covered.
	help_overlay = ColorRect.new()
	help_overlay.name = "GameHelpBackdrop"
	help_overlay.color = Color("#0b1727")
	help_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	help_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	help_overlay.visible = false
	menu_layer.add_child(help_overlay)
	var help_center = CenterContainer.new()
	help_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	help_center.offset_left = 18
	help_center.offset_right = -18
	help_center.offset_top = 18
	help_center.offset_bottom = -18
	help_overlay.add_child(help_center)
	var help_card = PanelContainer.new()
	help_card.custom_minimum_size = Vector2(min(560.0, screen_width - 40.0), min(760.0, get_viewport_rect().size.y - 40.0))
	help_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var help_card_style = StyleBoxFlat.new()
	help_card_style.bg_color = Color("#101f32")
	help_card_style.border_color = Color("#38bdf8")
	help_card_style.set_border_width_all(2)
	help_card_style.set_corner_radius_all(20)
	help_card_style.content_margin_left = 14
	help_card_style.content_margin_right = 14
	help_card_style.content_margin_top = 12
	help_card_style.content_margin_bottom = 12
	help_card.add_theme_stylebox_override("panel", help_card_style)
	help_center.add_child(help_card)
	var help_layout = VBoxContainer.new()
	help_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	help_layout.add_theme_constant_override("separation", 10)
	help_card.add_child(help_layout)
	var help_header = HBoxContainer.new()
	help_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help_layout.add_child(help_header)
	var help_heading = Label.new()
	help_heading.text = PersianText.reshaper("راهنمای بازی")
	help_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(help_heading, 22 if compact_layout else 20)
	help_heading.add_theme_color_override("font_color", Color("#f8fafc"))
	help_header.add_child(help_heading)
	var help_spacer = Control.new()
	help_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help_header.add_child(help_spacer)
	var help_close_button = Button.new()
	help_close_button.text = "✕"
	help_close_button.tooltip_text = "بستن راهنما"
	help_close_button.custom_minimum_size = Vector2(48, 46)
	_apply_font(help_close_button, 24)
	_style_button(help_close_button, false)
	help_close_button.connect("pressed", Callable(self, "_close_help"))
	help_header.add_child(help_close_button)
	help_body = VBoxContainer.new()
	help_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	help_body.add_theme_constant_override("separation", 10)
	help_layout.add_child(help_body)
	var menu_center = CenterContainer.new()
	menu_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_center.offset_left = 24
	menu_center.offset_right = -24
	menu_center.offset_top = 24
	menu_center.offset_bottom = -24
	menu_overlay.add_child(menu_center)
	menu_card = PanelContainer.new()
	menu_card.custom_minimum_size = Vector2(min(440.0, screen_width - 56.0), 0)
	menu_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var menu_card_style = StyleBoxFlat.new()
	menu_card_style.bg_color = Color("#101f32")
	menu_card_style.border_color = Color("#38bdf8")
	menu_card_style.set_border_width_all(2)
	menu_card_style.set_corner_radius_all(20)
	menu_card_style.content_margin_left = 18
	menu_card_style.content_margin_right = 18
	menu_card_style.content_margin_top = 18
	menu_card_style.content_margin_bottom = 18
	menu_card_style.shadow_color = Color(0, 0, 0, 0.55)
	menu_card_style.shadow_size = 18
	menu_card.add_theme_stylebox_override("panel", menu_card_style)
	menu_center.add_child(menu_card)
	var menu_heading = Label.new()
	menu_heading.text = PersianText.reshaper("منوی بازی")
	menu_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(menu_heading, 23 if compact_layout else 21)
	menu_heading.add_theme_color_override("font_color", Color("#f8fafc"))
	menu_card.add_child(menu_heading)
	var menu_scroll = ScrollContainer.new()
	menu_scroll.name = "PhoneMenuScroll"
	menu_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_scroll.custom_minimum_size = Vector2(0, min(560.0, max(220.0, get_viewport_rect().size.y - 150.0)))
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_card.add_child(menu_scroll)
	menu_panel = VBoxContainer.new()
	menu_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_panel.add_theme_constant_override("separation", 12)
	menu_scroll.add_child(menu_panel)
	menu_pause_button = _create_menu_action("⏸ توقف بازی", "toggle_pause")
	_create_menu_action("🔊 صدا و موسیقی", "open_audio_settings")
	_create_menu_action("⚙️ تنظیمات بازی", "open_game_settings")
	_create_menu_action("💾 ذخیره بازی", "save_from_menu")
	_create_menu_action("🔄 شروع دوباره شهر", "confirm_restart_from_menu")
	_create_menu_action("✕ بستن منو", "_close_game_menu")
	menu_button.connect("pressed", Callable(self, "_toggle_game_menu"))
	restart_confirm_panel = VBoxContainer.new()
	restart_confirm_panel.visible = false
	restart_confirm_panel.add_theme_constant_override("separation", 8)
	menu_panel.add_child(restart_confirm_panel)
	var restart_confirm_text = Label.new()
	restart_confirm_text.text = PersianText.reshaper("⚠️ شروع دوباره شهر؟\nتمام پیشرفت فعلی این شهر پاک می‌شود و یک شهر تازه ساخته خواهد شد.")
	restart_confirm_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart_confirm_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	restart_confirm_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart_confirm_text.custom_minimum_size = Vector2(0, 100 if compact_layout else 76)
	_apply_font(restart_confirm_text, 19 if compact_layout else 17)
	restart_confirm_text.add_theme_color_override("font_color", Color("#fde68a"))
	restart_confirm_panel.add_child(restart_confirm_text)
	var restart_yes_button = Button.new()
	restart_yes_button.text = PersianText.reshaper("بله، شروع دوباره")
	restart_yes_button.custom_minimum_size = Vector2(0, 54 if compact_layout else 46)
	restart_yes_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(restart_yes_button, 19 if compact_layout else 17)
	_style_button(restart_yes_button, false)
	restart_yes_button.connect("pressed", Callable(self, "_restart_city"))
	restart_confirm_panel.add_child(restart_yes_button)
	var restart_no_button = Button.new()
	restart_no_button.text = PersianText.reshaper("انصراف")
	restart_no_button.custom_minimum_size = Vector2(0, 54 if compact_layout else 46)
	restart_no_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(restart_no_button, 19 if compact_layout else 17)
	_style_button(restart_no_button, false)
	restart_no_button.connect("pressed", Callable(self, "_cancel_restart"))
	restart_confirm_panel.add_child(restart_no_button)
	_build_exit_confirmation(menu_layer)
	# Persistent city progression panel: stays visible above navigation on every page.
	var progress_panel = VBoxContainer.new()
	progress_panel.add_theme_constant_override("separation", 3)
	root.add_child(progress_panel)
	level_status_label = Label.new()
	level_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_status_label.add_theme_color_override("font_color", Color("#fbbf24"))
	_apply_font(level_status_label, 17 if compact_layout else 15)
	progress_panel.add_child(level_status_label)
	level_status_bar = ProgressBar.new()
	level_status_bar.min_value = 0
	level_status_bar.max_value = 100
	level_status_bar.value = 100
	level_status_bar.show_percentage = false
	level_status_bar.custom_minimum_size = Vector2(0, 10 if compact_layout else 8)
	var level_fill = StyleBoxFlat.new()
	level_fill.bg_color = Color("#d97706")
	level_fill.set_corner_radius_all(5)
	level_status_bar.add_theme_stylebox_override("fg", level_fill)
	var level_bg = StyleBoxFlat.new()
	level_bg.bg_color = Color("#334155")
	level_bg.set_corner_radius_all(5)
	level_status_bar.add_theme_stylebox_override("bg", level_bg)
	progress_panel.add_child(level_status_bar)
	xp_progress_label = Label.new()
	xp_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_progress_label.add_theme_color_override("font_color", Color("#a5f3fc"))
	_apply_font(xp_progress_label, 15 if compact_layout else 13)
	progress_panel.add_child(xp_progress_label)
	xp_progress_bar = ProgressBar.new()
	xp_progress_bar.min_value = 0
	xp_progress_bar.max_value = 100
	xp_progress_bar.show_percentage = false
	xp_progress_bar.custom_minimum_size = Vector2(0, 12 if compact_layout else 10)
	var xp_fill = StyleBoxFlat.new()
	xp_fill.bg_color = Color("#06b6d4")
	xp_fill.set_corner_radius_all(5)
	xp_progress_bar.add_theme_stylebox_override("fg", xp_fill)
	var xp_bg = StyleBoxFlat.new()
	xp_bg.bg_color = Color("#334155")
	xp_bg.set_corner_radius_all(5)
	xp_progress_bar.add_theme_stylebox_override("bg", xp_bg)
	progress_panel.add_child(xp_progress_bar)
	_update_progress_hud()
	var nav = GridContainer.new()
	main_navigation_grid = nav
	nav.name = "MainNavigationGrid"
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.columns = 2 if compact_layout else 3
	nav.add_theme_constant_override("h_separation", 8)
	nav.add_theme_constant_override("v_separation", 8)
	root.add_child(nav)
	navigation_buttons.clear()
	for item in [{"t":"شهر من","p":"home"},{"t":"ساختمان‌ها","p":"buildings"},{"t":"شهروندان","p":"citizens"},{"t":"بانک و امور مالی","p":"bank"},{"t":"شهرداری","p":"municipality"},{"t":"اقتصاد خصوصی","p":"private_economy"},{"t":"بازار و تجارت","p":"commerce"},{"t":"زیرساخت و توسعه شهر","p":"transport"},{"t":"انبار","p":"storage"},{"t":"گزارش","p":"report"},{"t":"پیشرفت و مأموریت‌ها","p":"missions"}]:
		var nav_item = VBoxContainer.new()
		nav_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav_item.add_theme_constant_override("separation", 2)
		if item.p == "missions":
			mission_reward_badge = Label.new()
			mission_reward_badge.text = ""
			mission_reward_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mission_reward_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			mission_reward_badge.custom_minimum_size = Vector2(0, 30)
			mission_reward_badge.add_theme_color_override("font_color", Color("#facc15"))
			mission_reward_badge.add_theme_color_override("font_color_shadow", Color("#111827"))
			mission_reward_badge.modulate = Color("#ffffff")
			_apply_font(mission_reward_badge, 17)
			nav_item.add_child(mission_reward_badge)
		var nav_title = str(item.t)
		if compact_layout:
			match str(item.p):
				"buildings": nav_title = "ساختمان"
				"bank": nav_title = "بانک"
				"private_economy": nav_title = "اقتصاد"
				"commerce": nav_title = "بازار"
				"transport": nav_title = "زیرساخت"
				"missions": nav_title = "پیشرفت"
				"progress": nav_title = "پیشرفت"
		var b = Button.new()
		var civic_page_locked = item.p in ["municipality", "private_economy"] and not game.has_municipal_hall()
		b.text = PersianText.reshaper(nav_title + (" 🔒" if civic_page_locked else ""))
		# Keep locked entries tappable so the player can learn how to unlock them.
		b.disabled = false
		b.custom_minimum_size = Vector2(0, 64 if compact_layout else 58)
		b.flat = false
		_apply_font(b, 17 if compact_layout else 18)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(b, true)
		navigation_buttons.append(b)
		b.connect("pressed", Callable(self, "_on_navigation_pressed").bind(item.p, b, nav_title))
		nav_item.add_child(b)
		nav.add_child(nav_item)
	var line = HSeparator.new()
	root.add_child(line)
	var scroll = ScrollContainer.new()
	game_scroll_container = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.clip_contents = true
	root.add_child(scroll)
	# Hide both scrollbars completely; scrolling remains available by touch/drag.
	var horizontal_bar = scroll.get_h_scroll_bar()
	var vertical_bar = scroll.get_v_scroll_bar()
	horizontal_bar.visible = false
	vertical_bar.visible = false
	horizontal_bar.modulate = Color(1, 1, 1, 0)
	vertical_bar.modulate = Color(1, 1, 1, 0)
	horizontal_bar.custom_minimum_size = Vector2(0, 0)
	vertical_bar.custom_minimum_size = Vector2(0, 0)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.custom_minimum_size = Vector2(0, 0)
	content.add_theme_constant_override("separation", 16 if compact_layout else 10)
	scroll.add_child(content)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_label.custom_minimum_size = Vector2(0, 76 if compact_layout else 58)
	var message_font = _apply_font(message_label, 27 if compact_layout else 23)
	if message_font != null:
		message_label.add_theme_constant_override("outline_size", 1)
		message_label.add_theme_color_override("font_outline_color", Color("#101827"))
	message_label.add_theme_color_override("font_color", Color("#ffffff"))
	message_label.modulate = Color("#ffffff")
	root.add_child(message_label)

func toggle_storage_production():
	storage_production_expanded = not storage_production_expanded
	show_page("storage")

func _get_daily_production_totals():
	var totals = {}
	var definitions = game.get_building_definitions()
	var resources = game.get_resource_definitions()
	var available_inputs = game.state.get("resources", {}).duplicate(true)
	for building_index in range(game.state.get("buildings", []).size()):
		var building = game.state.buildings[building_index]
		if int(building.get("rented_to", 0)) > 0:
			continue
		var building_id = str(building.get("id", ""))
		var data = definitions.get(building_id, {})
		var output_id = str(data.get("output", ""))
		if output_id.is_empty() or not resources.has(output_id):
			continue
		var workers = int(game._workers_for_building(building_index))
		var required_workers = int(data.get("jobs", 0))
		if workers <= 0:
			continue
		var amount = int(data.get("amount", 0))
		if required_workers > 0:
			amount = max(1, int(floor(float(amount) * float(workers) / float(required_workers))))
		var input_id = str(data.get("input", ""))
		var input_amount = int(data.get("input_amount", 0))
		if not input_id.is_empty():
			if required_workers > 0:
				input_amount = max(1, int(ceil(float(input_amount) * float(workers) / float(required_workers))))
			if int(available_inputs.get(input_id, 0)) < input_amount:
				continue
			available_inputs[input_id] = int(available_inputs.get(input_id, 0)) - input_amount
		if building_id == "woodcutter":
			amount = min(amount, int(game.state.get("forest_trees", 0)))
		if amount <= 0:
			continue
		totals[output_id] = int(totals.get(output_id, 0)) + amount
		available_inputs[output_id] = int(available_inputs.get(output_id, 0)) + amount
	return totals

func _update_mission_reward_badge():
	if mission_reward_badge == null or not is_instance_valid(mission_reward_badge) or game == null:
		return
	var ready_count = 0

	# Count only the first unclaimed daily mission, matching the mission page.
	for daily_mission in game.get_daily_missions():
		if bool(daily_mission.get("claimed", false)):
			continue
		if int(daily_mission.get("progress", 0)) >= int(daily_mission.get("goal", 1)):
			ready_count += 1
		break

	# Count only the first mission that is actually visible in the progression list.
	for mission in game.get_missions():
		var definition = {}
		for item in game.MISSION_DEFINITIONS:
			if str(item.id) == str(mission.get("id", "")):
				definition = item
				break
		if definition.is_empty():
			continue
		var is_legacy = bool(definition.get("legacy", false))
		var is_claimed = bool(mission.get("claimed", false))
		var is_unlocked = bool(mission.get("unlocked", false))
		if is_legacy:
			if is_claimed or not bool(mission.get("completed", false)):
				continue
		elif is_claimed or not is_unlocked:
			continue
		if bool(mission.get("completed", false)):
			ready_count += 1
		break

	mission_reward_badge.text = PersianText.reshaper("🎁 %d جایزه آماده" % ready_count if ready_count > 0 else "")
	mission_reward_badge.visible = ready_count > 0

func _create_menu_action(title, callback):
	var button = Button.new()
	button.text = PersianText.reshaper(title)
	var phone_layout = get_viewport_rect().size.x < 900
	# Keep menu actions compact and centered instead of stretching edge-to-edge.
	var action_width = min(320.0 if phone_layout else 360.0, get_viewport_rect().size.x - (88.0 if phone_layout else 160.0))
	button.custom_minimum_size = Vector2(max(220.0, action_width), 62 if phone_layout else 54)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_font(button, 19 if phone_layout else 17)
	_style_button(button, false)
	button.connect("pressed", Callable(self, callback))
	if audio_manager != null:
		button.connect("pressed", Callable(audio_manager, "play_sfx").bind("click"))
	menu_panel.add_child(button)
	return button

func _toggle_game_menu():
	if menu_panel == null or menu_overlay == null or not is_instance_valid(menu_overlay):
		return
	if exit_overlay != null and is_instance_valid(exit_overlay):
		exit_overlay.visible = false
	var should_open = not menu_overlay.visible
	menu_overlay.visible = should_open
	# Settings pages hide the menu contents while leaving the menu overlay closed.
	# Restore the contents whenever the player opens the menu again.
	menu_panel.visible = should_open
	_update_menu_pause_button()

func _close_game_menu():
	if menu_overlay != null and is_instance_valid(menu_overlay):
		menu_overlay.visible = false
	if restart_confirm_panel != null and is_instance_valid(restart_confirm_panel):
		restart_confirm_panel.visible = false

func _handle_device_back():
	# Android can deliver both KEY_BACK and NOTIFICATION_WM_GO_BACK_REQUEST
	# for one physical press. Debounce them so one press performs one action.
	var now_ticks = Time.get_ticks_msec()
	if now_ticks - last_device_back_ticks < 350:
		return
	last_device_back_ticks = now_ticks
	if exit_overlay != null and is_instance_valid(exit_overlay) and exit_overlay.visible:
		exit_overlay.visible = false
		return
	if help_overlay != null and is_instance_valid(help_overlay) and help_overlay.visible:
		_close_help()
		return
	if restart_confirm_panel != null and is_instance_valid(restart_confirm_panel) and restart_confirm_panel.visible:
		restart_confirm_panel.visible = false
		return
	if menu_overlay != null and is_instance_valid(menu_overlay) and menu_overlay.visible:
		_close_game_menu()
		return
	_show_exit_confirmation()

func _build_exit_confirmation(parent_layer):
	exit_overlay = ColorRect.new()
	exit_overlay.name = "ExitGameConfirmation"
	exit_overlay.color = Color(0.015, 0.035, 0.065, 0.86)
	exit_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	exit_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	exit_overlay.visible = false
	exit_overlay.z_index = 20
	parent_layer.add_child(exit_overlay)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 18
	center.offset_right = -18
	center.offset_top = 18
	center.offset_bottom = -18
	exit_overlay.add_child(center)
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(min(420.0, get_viewport_rect().size.x - 44.0), 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#14243a")
	style.border_color = Color("#f59e0b")
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	card.add_theme_stylebox_override("panel", style)
	center.add_child(card)
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	card.add_child(layout)
	var title = Label.new()
	title.text = PersianText.reshaper("خروج از بازی؟")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(title, 23)
	title.add_theme_color_override("font_color", Color("#f8fafc"))
	layout.add_child(title)
	var description = Label.new()
	description.text = PersianText.reshaper("می‌خواهی از مینی زکا سیتی خارج شوی؟ پیشرفتت ذخیره می‌شود.")
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(description, 16)
	description.add_theme_color_override("font_color", Color("#cbd5e1"))
	layout.add_child(description)
	var continue_button = Button.new()
	continue_button.text = PersianText.reshaper("ادامه بازی")
	continue_button.custom_minimum_size = Vector2(0, 60)
	continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(continue_button, 19)
	_style_button(continue_button, true)
	continue_button.pressed.connect(_cancel_exit_game)
	layout.add_child(continue_button)
	var exit_button = Button.new()
	exit_button.text = PersianText.reshaper("خروج از بازی")
	exit_button.custom_minimum_size = Vector2(0, 60)
	exit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(exit_button, 19)
	_style_button(exit_button, false)
	exit_button.pressed.connect(_confirm_exit_game)
	layout.add_child(exit_button)

func _show_exit_confirmation():
	if exit_overlay != null and is_instance_valid(exit_overlay):
		exit_overlay.visible = true

func _cancel_exit_game():
	if exit_overlay != null and is_instance_valid(exit_overlay):
		exit_overlay.visible = false

func _confirm_exit_game():
	if game != null:
		game.state["clock_last_unix"] = Time.get_unix_time_from_system()
		game.state["clock_cycle_seconds"] = int(clock_cycle_seconds)
		game.save_game()
	get_tree().quit()

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
		menu_overlay.visible = false

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
	game.state["clock_last_unix"] = Time.get_unix_time_from_system()
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
	if game != null:
		return str(game.get_geographic_rank_for_district_count(district_count).get("name", "آبادی کوچک"))
	return "آبادی کوچک"

func _load_ui_font():
	# Godot 4 uses FontFile itself as the font resource; the old DynamicFont
	# wrapper and its font_path/font_data/size properties no longer exist.
	ui_font = load("res://assets/fonts/Vazirmatn.ttf") as Font
	if ui_font == null:
		push_error("Could not load Vazirmatn font from res://assets/fonts/Vazirmatn.ttf")

func _apply_font(control, size=18):
	if ui_font == null:
		return null
	control.add_theme_font_override("font", ui_font)
	control.add_theme_font_size_override("font_size", int(size) + (5 if get_viewport_rect().size.x < 900 else 4))
	control.add_theme_constant_override("outline_size", 0)
	return ui_font

func _button_style(bg_color, border_color):
	return MainUITheme.button_style(bg_color, border_color)

func _style_button(button, navigation=false):
	MainUITheme.style_button(button, navigation)

func _clear_content():
	construction_time_labels.clear()
	for child in content.get_children():
		child.queue_free()

func _add_label(text, size=18):
	var label = Label.new()
	label.text = PersianText.reshaper(text)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_apply_font(label, size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size = Vector2(0, 44 if get_viewport_rect().size.x < 900 else 34)
	label.add_theme_color_override("font_color", Color("#f8fafc"))
	label.add_theme_color_override("font_color_shadow", Color("#0b1220"))
	label.modulate = Color("#ffffff")
	var target = active_section_container if active_section_container != null else content
	target.add_child(label)
	return label

func _add_button(text, button_target, callback, args=[]):
	var button = Button.new()
	button.text = PersianText.reshaper(text + "  ")
	button.custom_minimum_size = Vector2(0, 58 if get_viewport_rect().size.x < 900 else 50)
	_apply_font(button, 19 if get_viewport_rect().size.x < 900 else 17)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(button, false)
	if audio_manager != null and button_target != audio_manager:
		button.connect("pressed", Callable(audio_manager, "play_sfx").bind("click"))
	button.connect("pressed", Callable(button_target, callback).bindv(args))
	var parent = active_section_container if active_section_container != null else content
	parent.add_child(button)
	return button

func _toggle_commerce_section(section_id):
	var key = str(section_id)
	var was_expanded = bool(commerce_section_expanded.get(key, false))
	for existing_key in commerce_section_expanded.keys():
		commerce_section_expanded[existing_key] = false
	commerce_section_expanded[key] = not was_expanded
	show_page("commerce")

func _show_message(text):
	message_label.text = PersianText.reshaper(text)
	var report_text = str(text).strip_edges()
	# Keep temporary construction-blocking feedback out of the permanent city report.
	if report_text in ["برای ساخت این ساختمان جمعیت کافی نیست.", "به ساختمان موردنیاز این مأموریت رفتی."]:
		return
	if game != null and report_text != "" and game.has_method("add_report_event"):
		game.add_report_event(report_text)

func review_report_event(event_id):
	if game.review_report_event(event_id):
		show_page("report")
	else:
		_show_message("این گزارش قبلاً بررسی شده یا وجود ندارد.")

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
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(panel)
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)
	var welcome = Label.new()
	welcome.text = PersianText.reshaper("به شهر خودت خوش اومدی! برای شروع، به مأموریت‌ها برو.")
	welcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	welcome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(welcome, 18 if get_viewport_rect().size.x < 900 else 17)
	welcome.add_theme_color_override("font_color", Color("#ffffff"))
	layout.add_child(welcome)
	var go_button = Button.new()
	go_button.text = PersianText.reshaper("رفتن به مأموریت‌ها  ←")
	go_button.custom_minimum_size = Vector2(0, 54 if get_viewport_rect().size.x < 900 else 46)
	go_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(go_button, 19 if get_viewport_rect().size.x < 900 else 17)
	_style_button(go_button, false)
	go_button.connect("pressed", Callable(self, "_open_missions_from_welcome"))
	layout.add_child(go_button)


func open_audio_settings():
	# Close the full-screen modal backdrop as well as its card.
	if menu_overlay != null:
		menu_overlay.visible = false
	if menu_panel != null:
		menu_panel.visible = false
	show_page("audio")

func open_game_settings():
	# The backdrop is a full-screen input blocker; hiding only menu_panel
	# leaves it covering the settings page and makes the page seem not to open.
	if menu_overlay != null:
		menu_overlay.visible = false
	if menu_panel != null:
		menu_panel.visible = false
	show_page("settings")

func _apply_screen_orientation(mode):
	if OS.get_name() not in ["Android", "iOS"]:
		return
	match str(mode):
		"auto":
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR)
		"portrait":
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
		_:
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)

func set_screen_orientation(mode):
	var selected_mode = str(mode)
	if selected_mode not in ["auto", "portrait", "landscape"]:
		selected_mode = "auto"
	game.state["screen_orientation"] = selected_mode
	game.save_game()
	_apply_screen_orientation(selected_mode)
	show_page("settings")

func toggle_music_enabled():
	audio_manager.set_music_enabled(not audio_manager.is_music_enabled())
	show_page("audio")

func toggle_effects_enabled():
	audio_manager.set_effects_enabled(not audio_manager.is_effects_enabled())
	show_page("audio")

func toggle_environment_enabled():
	audio_manager.set_environment_enabled(not audio_manager.is_environment_enabled())
	show_page("audio")

func set_environment_mode(mode):
	audio_manager.set_environment_mode(str(mode))
	show_page("audio")

func preview_city_sound(kind):
	audio_manager.play_sfx(str(kind))

func _add_audio_slider(kind):
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(0, 42)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if kind == "music":
		slider.value = audio_manager.get_music_volume()
		slider.connect("value_changed", Callable(self, "_on_music_volume_changed"))
	elif kind == "environment":
		slider.value = audio_manager.get_environment_volume()
		slider.connect("value_changed", Callable(self, "_on_environment_volume_changed"))
	else:
		slider.value = audio_manager.get_effects_volume()
		slider.connect("value_changed", Callable(self, "_on_effects_volume_changed"))
	content.add_child(slider)

func _on_music_volume_changed(value):
	audio_manager.set_music_volume(value)

func _on_effects_volume_changed(value):
	audio_manager.set_effects_volume(value)

func _on_environment_volume_changed(value):
	audio_manager.set_environment_volume(value)

func _open_help():
	if help_overlay == null or not is_instance_valid(help_overlay) or game_scroll_container == null or not is_instance_valid(game_scroll_container):
		return
	help_previous_page = current_page if current_page != "help" else "home"
	var old_parent = game_scroll_container.get_parent()
	if old_parent != null:
		help_scroll_original_index = old_parent.get_children().find(game_scroll_container)
		old_parent.remove_child(game_scroll_container)
	if game_scroll_container.get_parent() == null:
		help_body.add_child(game_scroll_container)
	game_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_overlay.visible = false
	menu_panel.visible = false
	help_overlay.visible = true
	show_page("help")
	if game_scroll_container != null and is_instance_valid(game_scroll_container):
		game_scroll_container.scroll_vertical = 0

func _close_help():
	if help_overlay != null and is_instance_valid(help_overlay):
		help_overlay.visible = false
	if game_scroll_container != null and is_instance_valid(game_scroll_container):
		var old_parent = game_scroll_container.get_parent()
		if old_parent != null:
			old_parent.remove_child(game_scroll_container)
		if main_layout != null and is_instance_valid(main_layout):
			main_layout.add_child(game_scroll_container)
			main_layout.move_child(game_scroll_container, clamp(help_scroll_original_index, 0, main_layout.get_child_count() - 1))
	show_page(help_previous_page)

func _open_help_target(target_page):
	_close_help()
	show_page(str(target_page))

func _add_help_section(title, description, target_page=""):
	HelpPageBuilder.add_section(self, title, description, target_page)

func _open_missions_from_welcome():
	show_page("missions")
	if game_scroll_container != null and is_instance_valid(game_scroll_container):
		game_scroll_container.scroll_vertical = 0

func _add_progress_missions_tabs(active_page):
	var tabs = HBoxContainer.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_theme_constant_override("separation", 8)
	content.add_child(tabs)
	var missions_button = Button.new()
	missions_button.text = PersianText.reshaper("🎯 مأموریت‌ها")
	missions_button.custom_minimum_size = Vector2(0, 50 if get_viewport_rect().size.x < 900 else 44)
	missions_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(missions_button, 17)
	_style_button(missions_button, str(active_page) == "missions")
	missions_button.disabled = str(active_page) == "missions"
	missions_button.pressed.connect(Callable(self, "show_page").bind("missions"))
	tabs.add_child(missions_button)
	var progress_button = Button.new()
	progress_button.text = PersianText.reshaper("📈 پیشرفت شهر")
	progress_button.custom_minimum_size = Vector2(0, 50 if get_viewport_rect().size.x < 900 else 44)
	progress_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(progress_button, 17)
	_style_button(progress_button, str(active_page) == "progress")
	progress_button.disabled = str(active_page) == "progress"
	progress_button.pressed.connect(Callable(self, "show_page").bind("progress"))
	tabs.add_child(progress_button)

func _on_navigation_pressed(page, button, title):
	var civic_page_locked = page in ["municipality", "private_economy"] and not game.has_municipal_hall()
	button.text = PersianText.reshaper(str(title) + (" 🔒" if civic_page_locked else ""))
	if civic_page_locked:
		_show_message("برای باز شدن این بخش، ابتدا ساختمان شهرداری را بساز و ساخت آن را کامل کن.")
		return
	show_page(page)

func show_page(page):
	var civic_page_locked = page in ["municipality", "private_economy"] and not game.has_municipal_hall()
	if civic_page_locked:
		page = "home"
	current_page = page
	# Never let labels/buttons from a previous collapsible section attach to an old page.
	active_section_container = null
	_clear_content()
	_show_message("")
	if civic_page_locked:
		_show_message("برای باز شدن شهرداری و اقتصاد خصوصی، ابتدا ساختمان شهرداری را از بخش ساختمان‌ها بساز و منتظر تکمیل آن بمان.")
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
			_add_button("🏆 رتبه‌بندی", self, "show_page", ["ranking"])
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
			if not pending_decision.is_empty():
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
			if not recent_city_events.is_empty():
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
					if not category_rows.is_empty():
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
						home_button.add_theme_color_override("font_color", Color("#fde68a"))
				if selected_home_building_id != "" and game.get_building_count(selected_home_building_id) > 0:
					var selected_definition = game.get_building_definitions()[selected_home_building_id]
					var selected_count = game.get_building_count(selected_home_building_id)
					_add_label("انتخاب‌شده: %s  |  موجود: %d" % [selected_definition.name,selected_count], 17)
					_add_label("تعداد برای تخریب: %d" % selected_demolish_quantity, 16)
					var quantity_row = HBoxContainer.new()
					quantity_row.add_theme_constant_override("separation", 8)
					content.add_child(quantity_row)
					var less_button = Button.new()
					less_button.text = "−"
					less_button.custom_minimum_size = Vector2(70,58)
					_apply_font(less_button,24)
					_style_button(less_button,false)
					less_button.connect("pressed", Callable(self, "adjust_demolish_quantity").bind(-1))
					quantity_row.add_child(less_button)
					var more_button = Button.new()
					more_button.text = "+"
					more_button.custom_minimum_size = Vector2(70,58)
					_apply_font(more_button,24)
					_style_button(more_button,false)
					more_button.connect("pressed", Callable(self, "adjust_demolish_quantity").bind(1))
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
			var building_groups = {
				"مسکونی":["خانه‌ها"],
				"انبارها":["انبارها"],
				"اقتصادی":["کشاورزی","ماهیگیری","معادن","کارخانه‌ها","کسب‌وکارها"],
				"عمومی":["خدمات شهری","تفریح و فرهنگ"]
			}
			_add_label("گروه ساختمان‌ها | برای دیدن زیرگروه‌ها انتخاب کن", 19)
			var building_group_icons = {"مسکونی":"🏠", "انبارها":"📦", "اقتصادی":"🏭", "عمومی":"🏛️"}
			for group_name in ["مسکونی","انبارها","اقتصادی","عمومی"]:
				var group_expanded = selected_building_group == group_name
				var group_button = _add_button(("▼  " if group_expanded else "＋  ") + building_group_icons[group_name] + "  " + group_name + ("  |  انتخاب‌شده" if group_expanded else ""), self, "select_building_group", [group_name])
				group_button.custom_minimum_size.y = 76 if get_viewport_rect().size.x < 900 else 66
				var group_normal = Color("#263b52") if group_expanded else Color("#30343a")
				var group_hover = Color("#345574") if group_expanded else Color("#454b53")
				var group_pressed = Color("#1d3043") if group_expanded else Color("#20252b")
				group_button.add_theme_stylebox_override("normal", _button_style(group_normal, Color("#fbbf24") if group_expanded else Color("#7b8794")))
				group_button.add_theme_stylebox_override("hover", _button_style(group_hover, Color("#fcd34d") if group_expanded else Color("#cbd5e1")))
				group_button.add_theme_stylebox_override("focus", _button_style(group_hover, Color("#fcd34d") if group_expanded else Color("#cbd5e1")))
				group_button.add_theme_stylebox_override("pressed", _button_style(group_pressed, Color("#fbbf24")))
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
					content.add_child(subgroup_panel)
					var subgroup_list = VBoxContainer.new()
					subgroup_list.add_theme_constant_override("separation", 12)
					subgroup_panel.add_child(subgroup_list)
					var previous_section_container = active_section_container
					active_section_container = subgroup_list
					_add_label("زیرگروه‌های " + group_name, 18)
					for category in building_groups[group_name]:
						var category_expanded = selected_building_category == category
						var category_button = _add_button(("▼  " if category_expanded else "›  ") + category, self, "select_building_category", [category])
						category_button.custom_minimum_size.y = 64 if get_viewport_rect().size.x < 900 else 54
						if category_expanded:
							_add_building_category_items(category)
					active_section_container = previous_section_container
			if selected_building_category == "معادن":
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
							_add_label("سود در انتظار انتقال خودکار %s: %d سکه" % [str(building_definition.get("name", "ساختمان")), int(building.get("balance", 0))], 15)
			if district_ids.size() == 0:
				_add_label("هنوز ساختمانی در محله‌ای ساخته نشده است.", 15)
		"citizens":
			CitizensPage.build(self, s)
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
			if s.get("bank_transactions",[]).is_empty():
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
			if civic.get("requests", []).is_empty():
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
				request_row.add_theme_constant_override("separation", 8)
				content.add_child(request_row)
				var approve_button = Button.new()
				approve_button.text = "تأیید"
				_style_button(approve_button,false)
				_apply_font(approve_button,16)
				approve_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				approve_button.connect("pressed", Callable(self, "resolve_private_request").bind(int(request.get("id",0)),true))
				request_row.add_child(approve_button)
				var reject_button = Button.new()
				reject_button.text = "رد درخواست"
				_style_button(reject_button,false)
				_apply_font(reject_button,16)
				reject_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				reject_button.connect("pressed", Callable(self, "resolve_private_request").bind(int(request.get("id",0)),false))
				request_row.add_child(reject_button)
			if private_economy_data.get("requests", []).is_empty():
				_add_label("درخواستی در انتظار نیست. شهروندان با توجه به نیازهای شهر و سرمایه‌شان پیشنهادهای تازه می‌سازند.", 15)
			_add_label("🏗️ پروژه‌های مشارکتی در حال اجرا: %d" % int(private_economy_data.get("project_count",0)), 18)
			for project in private_economy_data.get("projects", []):
				var project_data = game.get_building_definitions().get(str(project.get("building_id","")),{"name":"پروژه شهری"})
				_add_label("%s | پیشنهاددهنده: شهروند %d | تحویل روز %d" % [str(project_data.get("name","پروژه شهری")),int(project.get("citizen_id",0)),int(project.get("finish_day",0))], 15)
				_add_label("سهم مردم: %d | سهم شهرداری: %d" % [int(project.get("citizen_contribution",0)),int(project.get("municipal_contribution",0))], 14)
			_add_label("🏪 کسب‌وکارهای مردم", 19)
			if private_economy_data.get("private_businesses", []).is_empty():
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
				if s.trade_shipments.is_empty():
					_add_label("محموله‌ای در راه نیست.")
				for shipment in s.trade_shipments:
					var shipment_city = game.get_import_cities().get(str(shipment.get("city_id","")) ,{"name":"نامشخص"})
					var shipment_resource = game.get_resource_definitions().get(str(shipment.get("resource_id","")) ,{"name":"کالای نامشخص"})
					_add_label("#%d | %s | %d واحد %s | تحویل روز %d" % [int(shipment.get("id",0)),shipment_city.name,int(shipment.get("amount",0)),shipment_resource.name,int(shipment.get("arrival_day",0))],15)
				_add_label("آخرین سفارش: "+str(s.get("last_import_report","")),15)
			_add_button(("▼ " if commerce_section_expanded.contracts else "▶ ") + "قراردادهای واردات", self, "_toggle_commerce_section", ["contracts"])
			if commerce_section_expanded.contracts:
				if s.import_contracts.is_empty():
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
			_add_label("🚧 زیرساخت و توسعه شهر",22)
			_add_label("🗺️ زمین و گسترش محدوده شهر",19)
			_add_label("زمین شهر: %d قطعه | اشغال‌شده: %d | آزاد: %d" % [int(s.get("land_owned",10)),game.get_land_used(),game.get_land_free()],17)
			_add_label("برای گسترش شهر زمین بخر؛ هر ساختمان چند قطعه از زمین را اشغال می‌کند.",15)
			var land_button = _add_button("خرید ۱ قطعه زمین | قیمت: %d سکه" % game.get_land_unit_price(), self, "buy_land")
			land_button.disabled = game.get_available_money() < game.get_land_unit_price()
			_add_label("🛣️ جاده‌ها و مسیرهای حمل‌ونقل",19)
			_add_label("جاده‌های اصلی شهر و مسیرهای بین‌شهری",19)
			_add_label("سطح جاده‌های بین‌شهری: %d از ۳" % int(s.get("road_level",1)),17)
			var road_level = int(s.get("road_level",1))
			if road_level < 3:
				var next_road_cost = 1500 if road_level == 1 else 3500
				var road_locked = int(s.level) < road_level+1
				var road_button = _add_button("احداث و ارتقای مسیر بین‌شهری به سطح %d%s — %d سکه" % [road_level+1, " 🔒" if road_locked else "", next_road_cost],self,"upgrade_road")
				road_button.disabled = not road_locked and game.get_available_money() < next_road_cost
			else:
				_add_label("مسیرهای بین‌شهری به بالاترین سطح رسیده‌اند.")
			_add_label("🚏 ایستگاه‌های حمل‌ونقل شهری",19)
			_add_label("ایستگاه اتوبوس: %d | ایستگاه تاکسی: %d" % [game.get_building_count("bus_station"),game.get_building_count("taxi_station")],16)
			for facility_id in ["bus_station","taxi_station"]:
				var facility = game.get_building_definitions().get(facility_id,{})
				if facility.is_empty():
					continue
				var facility_population = int(facility.get("unlock",0))
				var facility_level = int(facility.get("level_unlock",1))
				var facility_locked = int(s.level) < facility_level or int(s.population) < facility_population
				var facility_name = str(facility.get("name","ایستگاه")) + (" 🔒" if facility_locked else "")
				var facility_button = _add_button("ساخت "+facility_name+" — %d سکه | زمین: %d قطعه | جمعیت لازم: %d نفر | سطح: %d" % [int(facility.get("cost",0)),game.get_land_size(facility_id),facility_population,facility_level],self,"build_transport_facility",[facility_id])
				facility_button.disabled = false
			_add_label("🚚 پایانه و ناوگان کامیون",19)
			_add_label("پایانه حمل‌ونقل: %d | کامیون فعال: %d | ظرفیت روزانه: %d واحد" % [game.get_building_count("transport_depot"),game.get_transport_truck_count(),game.get_transport_daily_capacity()],17)
			_add_label("ظرفیت مصرف‌شده امروز: %d | ظرفیت باقی‌مانده: %d" % [int(s.get("transport_used_today",0)),game.get_transport_capacity_remaining()],16)
			_add_label("هر پایانه با ۲ کارمند، یک کامیون را فعال می‌کند؛ هر پایانه حداکثر ۲ کامیون پشتیبانی می‌کند.",15)
			_add_label("نگهداری روزانه ناوگان: %d سکه | نگهداری جاده: %d سکه" % [game.get_fleet_maintenance(),game.get_road_maintenance()],16)
			var depot = game.get_building_definitions().get("transport_depot",{})
			if not depot.is_empty():
				var depot_population = int(depot.get("unlock",0))
				var depot_level = int(depot.get("level_unlock",1))
				var depot_locked = int(s.level) < depot_level or int(s.population) < depot_population
				var depot_title = "ساخت پایانه حمل‌ونقل" + (" 🔒" if depot_locked else "")
				var depot_button = _add_button(depot_title+" — %d سکه | زمین: %d قطعه | جمعیت لازم: %d نفر | سطح: %d" % [int(depot.get("cost",0)),game.get_land_size("transport_depot"),depot_population,depot_level],self,"build_transport_facility",["transport_depot"])
				depot_button.disabled = false
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
			if s.trade_shipments.is_empty():
				_add_label("محموله‌ای در راه نیست.")
			for shipment in s.trade_shipments:
				var shipment_city = game.get_import_cities().get(str(shipment.get("city_id","")),{"name":"نامشخص"})
				var shipment_resource = game.get_resource_definitions().get(str(shipment.get("resource_id","")),{"name":"کالای نامشخص"})
				_add_label("#%d | %s | %d واحد %s | تحویل روز %d" % [int(shipment.get("id",0)),shipment_city.name,int(shipment.get("amount",0)),shipment_resource.name,int(shipment.get("arrival_day",0))],15)
			_add_label("آخرین سفارش: "+str(s.get("last_import_report","")),15)
			_add_label(" قراردادهای واردات:",18)
			if s.import_contracts.is_empty():
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
			var production_toggle = _add_button(("▼ " if storage_production_expanded else "▶ ") + "تولید روزانه شهر", self, "toggle_storage_production")
			_style_button(production_toggle, false)
			if storage_production_expanded:
				_add_label("فقط کالاهایی که ساختمان‌های تولیدی شهر می‌سازند؛ مقدار بر اساس کارگران و مواد اولیه فعلی محاسبه می‌شود.", 14)
				var production_totals = _get_daily_production_totals()
				if production_totals.is_empty():
					_add_label("در حال حاضر تولید فعالی نداری. برای شروع، یک ساختمان تولیدی بساز و نیروی کار آن را تأمین کن.", 16)
				else:
					for resource_id in production_totals.keys():
						_add_label("%s : %d در روز" % [str(game.get_resource_definitions()[resource_id].name), int(production_totals[resource_id])], 18)
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
				section_body.add_theme_constant_override("separation",5)
				section_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				content.add_child(section_body)
				active_section_container = section_body
				_add_label("موجودی انبار: %d | موجودی بازار: %d" % [current_amount,market_amount],16)
				_add_label("حداقل موجودی: %d | حداکثر موجودی: %d" % [int(rule.get("minimum",10)),int(rule.get("maximum",40))],16)
				var controls = HBoxContainer.new()
				controls.add_theme_constant_override("separation",6)
				controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				active_section_container.add_child(controls)
				var low_down = Button.new()
				low_down.text = PersianText.reshaper("حداقل −")
				_style_button(low_down,false)
				_apply_font(low_down,16)
				low_down.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				low_down.connect("pressed", Callable(self, "adjust_storage_rule").bind(id,"minimum",-5))
				controls.add_child(low_down)
				var low_up = Button.new()
				low_up.text = PersianText.reshaper("حداقل +")
				_style_button(low_up,false)
				_apply_font(low_up,16)
				low_up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				low_up.connect("pressed", Callable(self, "adjust_storage_rule").bind(id,"minimum",5))
				controls.add_child(low_up)
				var high_down = Button.new()
				high_down.text = PersianText.reshaper("حداکثر −")
				_style_button(high_down,false)
				_apply_font(high_down,16)
				high_down.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				high_down.connect("pressed", Callable(self, "adjust_storage_rule").bind(id,"maximum",-5))
				controls.add_child(high_down)
				var high_up = Button.new()
				high_up.text = PersianText.reshaper("حداکثر +")
				_style_button(high_up,false)
				_apply_font(high_up,16)
				high_up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				high_up.connect("pressed", Callable(self, "adjust_storage_rule").bind(id,"maximum",5))
				controls.add_child(high_up)
				_add_label("وقتی موجودی کم شد: "+("خرید از بازار" if str(rule.get("low_action","market")) == "market" else "افزایش تولید کارخانه"),15)
				_add_button("تغییر روش تأمین",self,"toggle_storage_low_action",[id])
				_add_label("وقتی موجودی زیاد شد: "+("فروش به بازار" if str(rule.get("high_action","market")) == "market" else "فروش از فروشگاه‌ها"),15)
				_add_button("تغییر روش فروش",self,"toggle_storage_high_action",[id])
				_add_button("اجرای تنظیمات همین ماده",self,"run_storage_rule",[id])
				active_section_container = null
			_add_label("ذخیره درختان جنگل: %d / ۱۰۰" % game.get_forest_tree_count())

		"report":
			CityReportPage.build(self, s)
		"settings":
			_add_label("⚙️ تنظیمات بازی", 24)
			_add_button("🏙️ تغییر نام شهر", self, "_open_city_name_setup", [false])
			_add_label("در حالت خودکار، بازی با چرخش گوشی هماهنگ می‌شود؛ حتی وقتی گوشی را ۱۸۰ درجه می‌چرخانی. دو حالت دیگر جهت صفحه را ثابت نگه می‌دارند.", 16)
			var current_orientation = str(game.state.get("screen_orientation", "landscape"))
			_add_button(("🔄 خودکار ✓" if current_orientation == "auto" else "🔄 خودکار"), self, "set_screen_orientation", ["auto"])
			_add_button(("📱 افقی ✓" if current_orientation == "landscape" else "📱 افقی"), self, "set_screen_orientation", ["landscape"])
			_add_button(("📱 عمودی ✓" if current_orientation == "portrait" else "📱 عمودی"), self, "set_screen_orientation", ["portrait"])
		"audio":
			AudioSettingsPage.build(self)
		"help":
			_add_label("❔ راهنمای کامل مینی زکا سیتی", 25)
			_add_label("اینجا هر زمان گیر کردی برگرد؛ از شروع بازی تا اقتصاد، ساختمان‌ها و رقابت شهرها را قدم‌به‌قدم توضیح داده‌ایم.", 17)
			_add_button("🏙️ برگشت به شهر من", self, "return_home_from_menu")
			_add_label("🚀 شروع سریع برای بازیکن تازه‌وارد", 21)
			_add_help_section("۱. اول مأموریت‌ها را انجام بده", "از دکمه مأموریت‌ها شروع کن. مأموریت‌های آموزشی به‌ترتیب خرید زمین، ساخت خانه، ساخت مزرعه، استخدام شهروند و توسعه خدمات را یاد می‌دهند. هر مأموریت را بخوان؛ اگر دکمه رفتن داشت، از همان برای رفتن مستقیم به بخش مربوط استفاده کن.", "missions")
			_add_help_section("۲. زمین و ساختمان بساز", "در ساختمان‌ها زمین تازه بخر و بعد ساختمان مناسب را انتخاب کن. قبل از ساخت، هزینه، زمان ساخت، ظرفیت و نیاز به نیروی کار را بررسی کن. همه ساختمان‌ها فوری آماده نمی‌شوند؛ پروژه‌های در حال ساخت و زمان باقی‌مانده بالای صفحه دیده می‌شود.", "buildings")
			_add_help_section("۳. شهروند و شغل را مدیریت کن", "خانه ظرفیت سکونت ایجاد می‌کند؛ اما برای تولید و درآمد، بعضی ساختمان‌ها به کارگر نیاز دارند. از بخش شهروندان تعداد شاغل، بیکار و وضعیت گروه‌های شهروندی را بررسی کن. بدون نیروی انسانی کافی، توسعه اقتصادی متوقف می‌شود.", "citizens")
			_add_label("💰 پول، درآمد و اقتصاد", 21)
			_add_help_section("خزانه و درآمد شهرداری", "در شهر من موجودی خزانه، ظرفیت خزانه، پول قفل‌شده و درآمد روزانه شهرداری را می‌بینی. سود کسب‌وکارها در حساب همان کسب‌وکار جمع می‌شود و در هر نوبت اقتصادی به‌صورت خودکار به خزانه منتقل می‌شود؛ اگر خزانه جا نداشته باشد، بخش منتقل‌نشده باقی می‌ماند تا بعداً واریز شود. ظرفیت خزانه محدود است؛ پول قفل‌شده را با پول آزاد اشتباه نگیر.", "home")
			_add_help_section("بانک، وام و امور مالی", "قبل از گرفتن وام، مبلغ دریافتی، بهره، زمان بازپرداخت و قسط را با درآمد پایدار شهر مقایسه کن. برای پرداخت هزینه‌های روزمره روی وام تکیه نکن؛ ابتدا درآمد و تولید منظم بساز.", "bank")
			_add_help_section("اقتصاد خصوصی و کسب‌وکارها", "کسب‌وکارها می‌توانند از فعالیت شهروندان و تقاضای شهر درآمد بسازند. تعداد ساختمان، نیروی کار، رضایت و دسترسی به کالا روی نتیجه اثر می‌گذارند. درآمد خصوصی را با مالیات و درآمد شهرداری جداگانه بررسی کن.", "private_economy")
			_add_help_section("بازار، تجارت و منابع", "در بازار می‌توانی کالا و منابع را بخری یا صادر کنی. قیمت خرید و فروش را مقایسه کن و همه ذخایر ضروری را نفروش؛ مواد اولیه برای زنجیره تولید و توسعه بعدی لازم می‌شوند. سفارش‌ها و محموله‌های در حال ارسال را پیگیری کن.", "commerce")
			_add_help_section("انبار و مدیریت موجودی", "انبار برای نگهداری منابع است. ظرفیت انبار محدود است؛ موجودی کالاها را بررسی کن و فضای کافی برای تولید بعدی نگه دار. اگر یک منبع کم است، زنجیره تولید وابسته به آن هم ممکن است متوقف شود.", "storage")
			_add_label("🏗️ توسعه، خدمات و زمان", 21)
			_add_help_section("خدمات شهری و رضایت", "آب، برق، خوراک، درمان، آموزش، امنیت، تفریح و بهداشت محیط نیازهای جداگانه‌اند. در شهر من میانگین پوشش خدمات را ببین و برای نیازهای ضعیف، ساختمان مناسب بساز. جمعیت بیشتر یعنی نیاز بیشتر به خدمات و زیرساخت.", "home")
			_add_help_section("شهرداری، زمین و محله‌ها", "پس از ساخت و تکمیل ساختمان شهرداری، بخش شهرداری باز می‌شود و می‌توانی زمین‌های خصوصی، مالیات، مجوزها، درخواست‌ها و پروژه‌های شهری را مدیریت کنی. ظرفیت ساخت هر محله و سهمیه ساختمان‌ها محدود است؛ پیش از خرید یا ساخت، محدودیت همان محله را بررسی کن و برای خدمات ضروری جا نگه دار.", "municipality")
			_add_help_section("روز، شب و ساخت‌وساز", "هر روز بازی ۱۰ دقیقه زمان واقعی دارد؛ ۷ دقیقه روز و ۳ دقیقه شب است. پایان روز، درآمدها، هزینه‌ها، تولید و رویدادها محاسبه می‌شوند. هم‌زمان حداکثر دو پروژه ساخت فعال می‌توانی داشته باشی؛ زمان ساخت را از بالای صفحه دنبال کن.", "home")
			_add_help_section("جاده و ناوگان", "جاده و ناوگان برای جابه‌جایی و پشتیبانی تجارت کاربرد دارند و می‌توانند هزینه نگهداری داشته باشند. پیش از توسعه مسیرها، درآمد و توان پرداخت هزینه‌های نگهداری را بررسی کن.", "transport")
			_add_label("🎯 مأموریت‌ها و سرگرمی‌های بلندمدت", 21)
			_add_help_section("مأموریت‌های روزانه و هفتگی", "مأموریت‌های روزانه با گذر روز عوض می‌شوند و مأموریت هفتگی هدف بزرگ‌تری دارد. انجام مأموریت همیشه به معنی دریافت جایزه نیست؛ اگر دکمه دریافت جایزه نمایش داده شد، آن را بزن. علامت هدیه بالای دکمه پیشرفت و مأموریت‌ها یعنی جایزه آماده دریافت داری.", "missions")
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


		"ranking":
			_add_label("🏆 رتبه‌بندی شهرها", 24)
			_add_label("اول رده جغرافیایی شهر، بعد XP و در صورت برابری هر دو، امتیاز توسعه تعیین‌کننده جایگاه است.", 16)
			var ranking_rows = game.get_rival_standings()
			var player_rank = 0
			for ranking_row in ranking_rows:
				if bool(ranking_row.get("is_player", false)):
					player_rank = int(ranking_row.get("rank", 0))
			if player_rank > 0:
				_add_label("👑 رتبه فعلی شهر تو: %d از %d" % [player_rank, ranking_rows.size()], 20)
			for ranking_row in ranking_rows:
				var ranking_prefix = "👑 " if bool(ranking_row.get("is_player", false)) else "🏘️ "
				var ranking_name = str(ranking_row.get("name", "شهر"))
				var ranking_card_text = "%sرتبه %d ـ %s\nرده جغرافیایی: %s  |  XP: %d\nامتیاز توسعه: %d\nجمعیت: %d نفر  |  سطح: %d" % [ranking_prefix, int(ranking_row.get("rank", 0)), ranking_name, str(ranking_row.get("geographic_rank", "آبادی کوچک")), int(ranking_row.get("xp", 0)), int(ranking_row.get("score", 0)), int(ranking_row.get("population", 0)), int(ranking_row.get("level", 1))]
				_add_label(ranking_card_text, 18)
			_add_label("نکته: این رتبه‌بندی فعلاً بین شهرهای رقیب داخل همین ذخیره بازی محاسبه می‌شود و آنلاین یا جهانی نیست.", 14)
			_add_button("🏙️ بازگشت به شهر", self, "show_page", ["home"])

		"progress":
			_add_progress_missions_tabs("progress")
			_add_label("🏗️ هدف‌های بلندمدت شهر",23)
			_add_label("این هدف‌ها با ساخت‌وساز و رشد شهر کامل می‌شوند. پیشرفت هر هدف ذخیره می‌شود و پس از تکمیل، می‌توانی جایزه‌اش را دریافت کنی.",16)
			for project in game.get_long_term_projects():
				var project_done = int(project.progress) >= int(project.goal)
				_add_label(str(project.title),19)
				_add_label(str(project.description),16)
				_add_label("میزان پیشرفت: %d از %d\nجایزه: %d سکه و %d تجربه" % [int(project.progress),int(project.goal),int(project.reward),int(project.xp)],16)
				var project_bar = ProgressBar.new()
				project_bar.min_value = 0
				project_bar.max_value = max(1,int(project.goal))
				project_bar.value = int(project.progress)
				project_bar.show_percentage = false
				project_bar.custom_minimum_size = Vector2(0,12)
				content.add_child(project_bar)
				if bool(project.claimed):
					_add_label("✓ این جایزه را دریافت کرده‌ای",15)
				elif project_done:
					_add_button("🎁 دریافت جایزه پروژه",self,"claim_long_term_project",[str(project.id)])
				else:
					_add_label("● هنوز در حال تکمیل این هدف هستی",15)

			_add_label("🏙️ رتبه‌بندی شهرها",23)
			_add_label("ابتدا رده جغرافیایی، سپس XP و در نهایت امتیاز توسعه رتبه شهرها را تعیین می‌کند.",15)
			for rival_row in game.get_rival_standings():
				var rival_prefix = "👑 " if bool(rival_row.get("is_player",false)) else "🏘️ "
				_add_label("%sرتبه %d ـ %s\nرده جغرافیایی: %s | XP: %d\nامتیاز توسعه: %d | جمعیت: %d نفر | سطح: %d" % [rival_prefix,int(rival_row.get("rank",0)),str(rival_row.get("name","")),str(rival_row.get("geographic_rank","آبادی کوچک")),int(rival_row.get("xp",0)),int(rival_row.get("score",0)),int(rival_row.get("population",0)),int(rival_row.get("level",1))],16)
			_add_label("🔎 رازها و کشفیات",23)
			var mystery = game.get_mystery_status()
			if bool(mystery.get("active",false)):
				_add_label("سرنخ تازه: "+str(mystery.get("title","راز مخفی")),18)
				_add_label(str(mystery.get("clue","")),15)
				_add_label(str(mystery.get("objective","")),16)
				_add_label("پیشرفت سرنخ: %d از %d\nپاداش کشف: %d سکه و %d تجربه" % [int(mystery.get("progress",0)),int(mystery.get("goal",1)),int(mystery.get("reward",0)),int(mystery.get("xp",0))],16)
				if int(mystery.get("progress",0)) >= int(mystery.get("goal",1)):
					_add_button("🗝️ باز کردن راز و دریافت جایزه",self,"claim_mystery_reward")
			else:
				_add_label("فعلاً سرنخ تازه‌ای پیدا نکرده‌ای. با پیشرفت شهر و گذشت روزها، ممکن است راز تازه‌ای کشف شود.",15)
				_add_label("تعداد رازهای کشف‌شده: %d" % int(mystery.get("completed",0)),15)
			_add_label("🏛️ پروژه‌های بزرگ شهری",23)
			var landmark_status = game.get_landmark_project_status()
			if bool(landmark_status.get("active",false)):
				var stage_data = landmark_status.get("stage_data",{})
				_add_label("پروژه در حال اجرا: %s\nمرحله %d از %d" % [str(landmark_status.get("title","")),int(landmark_status.get("stage",1)),int(landmark_status.get("stage_total",1))],18)
				_add_label("کار این مرحله: %s\nهزینه تکمیل: %d سکه" % [str(stage_data.get("title","")),int(stage_data.get("cost",0))],16)
				_add_label("برای انجام این مرحله لازم است: سطح شهر %d، جمعیت %d نفر و دست‌کم %d ساختمان داشته باشی." % [int(stage_data.get("level",1)),int(stage_data.get("population",0)),int(stage_data.get("buildings",0))],15)
				var stage_button = _add_button("🏗️ سرمایه‌گذاری و تکمیل این مرحله",self,"invest_landmark_stage")
				stage_button.disabled = not bool(landmark_status.get("requirements_met",false)) or game.get_available_money() < int(stage_data.get("cost",0))
			else:
				_add_label("در هر زمان فقط یک پروژه بزرگ را می‌توانی دنبال کنی. هر پروژه چند مرحله دارد و برای عبور از هر مرحله باید شرط‌های آن را فراهم کنی و هزینه‌اش را بپردازی.",15)
				for landmark in game.get_landmark_project_definitions():
					var completed_landmarks = landmark_status.get("completed",[])
					var is_completed_landmark = str(landmark.id) in completed_landmarks
					_add_label("%s\nجایزه پس از افتتاح: %d سکه و %d تجربه" % [str(landmark.title),int(landmark.reward),int(landmark.xp)],17)
					_add_label(str(landmark.description),14)
					if is_completed_landmark:
						_add_label("✓ این سازه در شهر افتتاح شده است",15)
					else:
						_add_button("آغاز پروژه "+str(landmark.title),self,"start_landmark_project",[str(landmark.id)])

			_add_label("🏆 رتبه، افتخارات و رکوردهای شهر",23)
			var league = game.get_city_league()
			_add_label("رده امتیاز توسعه: %s\nامتیاز توسعه: %d" % [str(league.name),int(league.score)],19)
			if int(league.next) > 0:
				_add_label("برای رسیدن به رده امتیاز توسعه بعدی، %d امتیاز دیگر لازم داری." % max(0,int(league.next)-int(league.score)),15)
			_add_label("این رتبه فقط بر اساس وضعیت شهر خودت محاسبه می‌شود و جدول رتبه‌بندی جهانی نیست.",14)
			var weekly = game.get_weekly_challenge()
			_add_label("🏁 چالش این هفته: "+str(weekly.title),19)
			_add_label(str(weekly.description),15)
			_add_label("پیشرفت این هفته: %d از %d\nجایزه: %d سکه و %d تجربه" % [int(weekly.progress),int(weekly.goal),int(weekly.reward),int(weekly.xp)],16)
			if bool(weekly.claimed):
				_add_label("✓ جایزه چالش این هفته را دریافت کرده‌ای.",15)
			elif int(weekly.progress) >= int(weekly.goal):
				_add_button("🏆 دریافت جایزه رقابت هفتگی",self,"claim_weekly_challenge")
			var records = game.get_city_records()
			_add_label("📊 رکوردهای ثبت‌شده شهر",19)
			_add_label("بیشترین جمعیت ثبت‌شده: %d نفر\nبیشترین موجودی خزانه: %d سکه" % [int(records.get("peak_population",0)),int(records.get("peak_money",0))],16)
			_add_label("بالاترین سطح شهر: %d\nبیشترین رضایت ثبت‌شده: %d از ۱۰۰\nبیشترین تعداد ساختمان: %d" % [int(records.get("peak_level",1)),int(records.get("peak_satisfaction",0)),int(records.get("most_buildings",0))],16)
			var achievement_list = game.get_achievements()
			var unlocked_achievements = 0
			for achievement in achievement_list:
				if bool(achievement.unlocked):
					unlocked_achievements += 1
			_add_label("افتخارات به‌دست‌آمده: %d از %d" % [unlocked_achievements,achievement_list.size()],17)
			for achievement in achievement_list:
				var achievement_status = "🏅 بازشده" if bool(achievement.unlocked) else "🔒 هنوز باز نشده"
				_add_label(achievement_status+" | "+str(achievement.title),18)
				_add_label(str(achievement.description),15)
		"missions":
			_add_progress_missions_tabs("missions")
			_add_label("📅 مأموریت‌های روزانه", 23)
			_add_label("هر روز سه هدف تازه برای توسعه شهر؛ پیشرفت و جایزه‌ها جدا از مأموریت‌های اصلی ذخیره می‌شوند.", 16)
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
				content.add_child(daily_card)
				var daily_body = VBoxContainer.new()
				daily_body.add_theme_constant_override("separation", 5)
				daily_card.add_child(daily_body)
				var daily_title = Label.new()
				daily_title.text = PersianText.reshaper(str(daily_mission.title))
				daily_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				daily_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				_apply_font(daily_title, 18)
				daily_title.add_theme_color_override("font_color", Color("#fde68a") if daily_done else Color("#ffffff"))
				daily_body.add_child(daily_title)
				var daily_desc = Label.new()
				daily_desc.text = PersianText.reshaper(str(daily_mission.description))
				daily_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				daily_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				_apply_font(daily_desc, 16)
				daily_desc.add_theme_color_override("font_color", Color("#dbeafe"))
				daily_body.add_child(daily_desc)
				var daily_progress = Label.new()
				daily_progress.text = PersianText.reshaper("پیشرفت: %d از %d  |  جایزه: %d سکه + %d تجربه" % [int(daily_mission.progress), int(daily_mission.goal), int(daily_mission.reward), int(daily_mission.xp)])
				daily_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				daily_progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				_apply_font(daily_progress, 15)
				daily_body.add_child(daily_progress)
				if bool(daily_mission.claimed):
					var daily_status = Label.new()
					daily_status.text = PersianText.reshaper("✓ جایزه امروز دریافت شده")
					daily_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
					_apply_font(daily_status, 16)
					daily_status.add_theme_color_override("font_color", Color("#86efac"))
					daily_body.add_child(daily_status)
				elif daily_done:
					_add_daily_claim_button(daily_body, str(daily_mission.id))
				else:
					var daily_go_button = Button.new()
					daily_go_button.text = PersianText.reshaper("رفتن ←")
					daily_go_button.custom_minimum_size = Vector2(132 if get_viewport_rect().size.x < 900 else 144, 42 if get_viewport_rect().size.x < 900 else 38)
					daily_go_button.size_flags_horizontal = Control.SIZE_SHRINK_END
					_apply_font(daily_go_button, 17)
					_style_button(daily_go_button, false)
					daily_go_button.connect("pressed", Callable(self, "go_to_mission_target").bind(str(daily_mission.id)))
					daily_body.add_child(daily_go_button)
					var daily_waiting = Label.new()
					daily_waiting.text = PersianText.reshaper("● در حال انجام")
					daily_waiting.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
					_apply_font(daily_waiting, 15)
					daily_waiting.add_theme_color_override("font_color", Color("#cbd5e1"))
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
			_add_label("اصلی: %d از %d تکمیل‌شده   |   فرعی: %d از %d تکمیل‌شده" % [main_claimed,main_total,side_claimed,side_total],17)
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
			content.add_child(summary_panel)
			var summary_label = Label.new()
			summary_label.text = PersianText.reshaper("پیشرفت کلی مأموریت‌ها: %d از %d" % [main_claimed + side_claimed, main_total + side_total])
			summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_apply_font(summary_label, 19)
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
						_add_label("🎁 پاداش‌های باقی‌مانده از نسخه قبلی", 21)
						_add_label("اگر در نسخه قبلی مأموریتی را کامل کرده بودی اما جایزه‌اش را نگرفته بودی، اینجا هنوز قابل دریافت است.",15)
					elif mission_type == "main":
						_add_label("📘 مأموریت‌های اصلی", 21)
					else:
						_add_label("⭐ مأموریت‌های فرعی", 21)
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
				content.add_child(card)
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
				title_label.text = PersianText.reshaper(str(definition.title))
				title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				title_label.clip_text = false
				title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				title_label.custom_minimum_size = Vector2(0, 34)
				title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				_apply_font(title_label, 19)
				title_label.add_theme_color_override("font_color", Color("#86efac") if is_claimed else (Color("#fde68a") if is_completed else Color("#ffffff")))
				title_row.add_child(title_label)
				var status_label = Label.new()
				status_label.text = PersianText.reshaper(status_text)
				status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				status_label.clip_text = false
				status_label.custom_minimum_size = Vector2(0, 30)
				status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				_apply_font(status_label, 16)
				status_label.add_theme_color_override("font_color", Color("#86efac") if is_claimed else (Color("#fde68a") if is_completed else Color("#cbd5e1")))
				card_body.add_child(status_label)
				var description_label = Label.new()
				description_label.text = PersianText.reshaper(str(definition.description))
				description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				description_label.clip_text = false
				description_label.custom_minimum_size = Vector2(0, 48)
				description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				_apply_font(description_label, 17)
				description_label.add_theme_color_override("font_color", Color("#f8fafc"))
				card_body.add_child(description_label)
				var current_progress = int(mission.get("progress", 0))
				var target_progress = max(1, int(definition.goal))
				var progress_label = Label.new()
				progress_label.text = PersianText.reshaper("پیشرفت: %d از %d     |     پاداش: %d سکه + %d تجربه" % [current_progress, target_progress, int(definition.reward), int(definition.get("xp",0))])
				progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				progress_label.clip_text = false
				progress_label.custom_minimum_size = Vector2(0, 34)
				progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				_apply_font(progress_label, 16)
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
					hint_label.text = PersianText.reshaper("راهنما: " + str(definition.get("hint", "از بخش‌های شهر هدف را دنبال کن.")))
					hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
					hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					hint_label.clip_text = false
					hint_label.custom_minimum_size = Vector2(0, 48)
					hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					_apply_font(hint_label, 16)
					hint_label.add_theme_color_override("font_color", Color("#cbd5e1"))
					card_body.add_child(hint_label)
				var go_button = Button.new()
				go_button.text = PersianText.reshaper("رفتن به بخش مربوط  ←")
				go_button.custom_minimum_size = Vector2(148 if get_viewport_rect().size.x < 900 else 160, 44 if get_viewport_rect().size.x < 900 else 40)
				go_button.size_flags_horizontal = Control.SIZE_SHRINK_END
				_apply_font(go_button, 17 if get_viewport_rect().size.x < 900 else 16)
				_style_button(go_button, false)
				go_button.connect("pressed", Callable(self, "go_to_mission_target").bind(str(mission.get("id", ""))))
				card_body.add_child(go_button)
				if is_unlocked and is_completed and not is_claimed:
					var claim_button = Button.new()
					claim_button.text = PersianText.reshaper("🎁 دریافت جایزه و باز کردن مرحله بعد")
					claim_button.custom_minimum_size = Vector2(0, 58 if get_viewport_rect().size.x < 900 else 50)
					claim_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					_apply_font(claim_button, 18)
					_style_button(claim_button, false)
					claim_button.connect("pressed", Callable(self, "claim_mission").bind(mission_index))
					card_body.add_child(claim_button)
			if visible_missions == 0:
				_add_label("آموزش هنوز شروع نشده است؛ بازی را ادامه بده.", 17)
		_:
			_add_label("بخش پیدا نشد.")
	# Extra scrollable safe area so the last controls/text stay above Android browser navigation bars.
	var bottom_scroll_space = Control.new()
	bottom_scroll_space.custom_minimum_size = Vector2(0, 180 if get_viewport_rect().size.x < 900 else 90)
	bottom_scroll_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(bottom_scroll_space)
	var header_stats = "خزانه: %d  |  جمعیت: %d" % [s.money,s.population]
	var city_title = str(s.get("city_name", "شهر من")).strip_edges()
	if city_title.is_empty():
		city_title = "شهر من"
	var header_text = city_title + "\n" + header_stats
	header_label.text = PersianText.reshaper(header_text)

func _municipality_section(title, section_id):
	var expanded = bool(municipality_section_expanded.get(section_id, false))
	var header = _add_button(("▼ " if expanded else "▶ ") + title, self, "toggle_municipality_section", [section_id])
	active_section_container = VBoxContainer.new()
	active_section_container.add_theme_constant_override("separation", 5)
	active_section_container.visible = expanded
	content.add_child(active_section_container)

func _end_municipality_section():
	active_section_container = null

func toggle_citizen_status_group(group_name):
	var key = str(group_name)
	var was_expanded = bool(citizen_status_expanded.get(key, false))
	for existing_key in citizen_status_expanded.keys():
		citizen_status_expanded[existing_key] = false
	citizen_status_expanded[key] = not was_expanded
	show_page("citizens")

func toggle_municipality_section(section_id):
	var key = str(section_id)
	var was_expanded = bool(municipality_section_expanded.get(key, false))
	for existing_key in municipality_section_expanded.keys():
		municipality_section_expanded[existing_key] = false
	municipality_section_expanded[key] = not was_expanded
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
	panel.add_theme_stylebox_override("panel", panel_style)
	content.add_child(panel)
	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 9)
	panel.add_child(body)

	var total_coverage = 0
	var service_count = game.SERVICE_GROUPS.size()
	for service_id in game.SERVICE_GROUPS.keys():
		total_coverage += int(city_state.get("services", {}).get(service_id, 0))
	var average_coverage = int(round(float(total_coverage) / float(max(1, service_count))))
	var header = Button.new()
	header.text = PersianText.reshaper(("%s  🏙️  خدمات و زیرساخت شهر" % ("▼" if home_city_details_expanded else "▶")) + "     میانگین پوشش: %d%%" % average_coverage)
	header.custom_minimum_size = Vector2(0, 62 if compact else 54)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_apply_font(header, 19 if compact else 17)
	_style_button(header, false)
	header.connect("pressed", Callable(self, "toggle_home_city_details"))
	body.add_child(header)

	var hint = Label.new()
	hint.text = PersianText.reshaper("وضعیت آب، برق، درمان، امنیت و امکانات شهر را یک‌جا ببین.")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(hint, 15 if compact else 14)
	hint.add_theme_color_override("font_color", Color("#cbd5e1"))
	body.add_child(hint)

	if not home_city_details_expanded:
		return

	var section_line = HSeparator.new()
	body.add_child(section_line)
	var section_title = Label.new()
	section_title.text = PersianText.reshaper("شاخص خدمات شهری")
	section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_apply_font(section_title, 18)
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
	infra_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_apply_font(infra_title, 18)
	infra_title.add_theme_color_override("font_color", Color("#f8fafc"))
	body.add_child(infra_title)
	var central_bank_status = "فعال" if game.has_central_bank() else ("بازسازی: %d روز" % int(city_state.get("central_bank_rebuild_days_left", 0)) if int(city_state.get("central_bank_rebuild_days_left", 0)) > 0 else "ساخته نشده")
	var infrastructure_text = "ساختمان‌ها: %d   |   ظرفیت انبار: %d\nبانک مرکزی: %s   |   بانک شهری: %d\nجنگل: %d/۱۰۰ درخت   |   معادن فعال: %d" % [city_state.buildings.size(), game.get_storage_capacity(), central_bank_status, game.get_building_count("municipal_bank"), game.get_forest_tree_count(), _active_mine_count()]
	var infra_label = Label.new()
	infra_label.text = PersianText.reshaper(infrastructure_text)
	infra_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	infra_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	infra_label.custom_minimum_size = Vector2(0, 76 if compact else 64)
	_apply_font(infra_label, 16 if compact else 15)
	infra_label.add_theme_color_override("font_color", Color("#dbeafe"))
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
	card.add_theme_stylebox_override("panel", card_style)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	card.add_child(stack)

	var title = Label.new()
	title.text = PersianText.reshaper("%s  (%d ساختمان)" % [title_text, building_count])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(0, 38 if compact else 32)
	_apply_font(title, 16 if compact else 15)
	title.add_theme_color_override("font_color", Color("#f8fafc"))
	stack.add_child(title)

	var coverage_label = Label.new()
	coverage_label.text = PersianText.reshaper("پوشش خدمات: %d٪" % coverage)
	coverage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_apply_font(coverage_label, 15)
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
	need_label.text = PersianText.reshaper("رضایت از این نیاز: %d٪" % need)
	need_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_apply_font(need_label, 14)
	need_label.add_theme_color_override("font_color", Color("#cbd5e1"))
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
	if category == "ماهیگیری":
		_add_label("پهنه‌های آبی به‌صورت طبیعی در شهر وجود دارند؛ برای آغاز صید، اسکله صیادی بساز.", 15)
	var visible_buildings = 0
	var definitions = game.get_building_definitions()
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
	building_ids.sort_custom(Callable(self, "_sort_building_ids_by_unlock_priority"))
	for id in building_ids:
		var data = definitions[id]
		visible_buildings += 1
		var s = game.state
		var population_unlocked = int(s.population) >= int(data.get("unlock", 0))
		var required_level = int(data.get("level_unlock", 1))
		var level_unlocked = int(s.level) >= required_level
		var unlocked = population_unlocked and level_unlocked
		var label = "%s%s | هزینه: %d | زمین: %d قطعه | جمعیت: %d | سطح: %d" % [data.name, "" if unlocked else " 🔒", data.cost,game.get_land_size(id),data.unlock,required_level]
		var building_button = _add_button(label, self, "build_building", [id])
		# Locked buildings stay tappable so their exact unlock requirements can be explained.
		building_button.disabled = false
		if id == mission_target_building_id:
			building_button.modulate = Color("#fde68a")
			building_button.name = "MissionTargetBuilding"
			mission_target_building_button = building_button
	if visible_buildings == 0:
		_add_label("در این دسته ساختمانی تعریف نشده است.", 16)

func select_building_group(group_name):
	var requested = str(group_name)
	selected_building_group = "" if selected_building_group == requested else requested
	selected_building_category = ""
	show_page("buildings")

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
	show_page("transport")
	_show_message(result.message)

func build_building(id):
	var data = game.get_building_definitions().get(str(id), {})
	if data.is_empty():
		return
	var required_level = int(data.get("level_unlock", 1))
	var required_population = int(data.get("unlock", 0))
	var current_level = int(game.state.get("level", 1))
	var current_population = int(game.state.get("population", 0))
	if current_level < required_level or current_population < required_population:
		var reasons = []
		if current_level < required_level:
			reasons.append("سطح شهر باید به %d برسد (سطح فعلی: %d)" % [required_level, current_level])
		if current_population < required_population:
			reasons.append("جمعیت شهر باید به %d نفر برسد (جمعیت فعلی: %d)" % [required_population, current_population])
		_show_message("🔒 برای باز شدن %s: %s." % [str(data.get("name", "این ساختمان")), " و ".join(reasons)])
		return
	var previous_level = int(game.state.get("level", 1))
	var result = game.build(id)
	if bool(result.get("ok", false)):
		audio_manager.play_sfx("construction")
		if int(game.state.get("level", 1)) > previous_level:
			audio_manager.play_sfx("level")
	show_page("buildings")
	_show_message(result.message)

func toggle_home_city_details():
	var was_expanded = home_city_details_expanded
	home_city_details_expanded = not was_expanded
	if not was_expanded:
		home_buildings_expanded = false
		home_economy_expanded = false
		demolish_panel_expanded = false
	show_page("home")

func toggle_home_buildings():
	var was_expanded = home_buildings_expanded
	home_buildings_expanded = not was_expanded
	if not was_expanded:
		home_city_details_expanded = false
		home_economy_expanded = false
		demolish_panel_expanded = false
	show_page("home")

func toggle_home_economy():
	var was_expanded = home_economy_expanded
	home_economy_expanded = not was_expanded
	if not was_expanded:
		home_city_details_expanded = false
		home_buildings_expanded = false
		demolish_panel_expanded = false
	show_page("home")

func toggle_demolish_panel():
	var was_expanded = demolish_panel_expanded
	demolish_panel_expanded = not was_expanded
	if not was_expanded:
		home_city_details_expanded = false
		home_buildings_expanded = false
		home_economy_expanded = false
	show_page("home")

func select_home_building(id):
	selected_home_building_id = str(id)
	demolish_panel_expanded = true
	home_city_details_expanded = false
	home_buildings_expanded = false
	home_economy_expanded = false
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
	var current_road_level = int(game.state.get("road_level", 1))
	var required_city_level = current_road_level + 1
	var current_city_level = int(game.state.get("level", 1))
	if current_city_level < required_city_level:
		_show_message("🔒 برای ارتقای جاده، سطح شهر باید به %d برسد (سطح فعلی: %d)." % [required_city_level, current_city_level])
		return
	var result = game.upgrade_roads()
	show_page("transport")
	_show_message(result.message)

func build_transport_facility(building_id):
	var data = game.get_building_definitions().get(str(building_id), {})
	if data.is_empty():
		return
	var required_level = int(data.get("level_unlock", 1))
	var required_population = int(data.get("unlock", 0))
	var current_level = int(game.state.get("level", 1))
	var current_population = int(game.state.get("population", 0))
	if current_level < required_level or current_population < required_population:
		var reasons = []
		if current_level < required_level:
			reasons.append("سطح شهر باید به %d برسد (سطح فعلی: %d)" % [required_level, current_level])
		if current_population < required_population:
			reasons.append("جمعیت شهر باید به %d نفر برسد (جمعیت فعلی: %d)" % [required_population, current_population])
		_show_message("🔒 برای باز شدن %s: %s." % [str(data.get("name", "این ایستگاه")), " و ".join(reasons)])
		return
	var previous_level = int(game.state.get("level", 1))
	var result = game.build(str(building_id))
	if bool(result.get("ok", false)):
		audio_manager.play_sfx("construction")
		if int(game.state.get("level", 1)) > previous_level:
			audio_manager.play_sfx("level")
	show_page("transport")
	_show_message(result.message)

func advance_day():
	var report = game.end_day()
	game.state["clock_last_unix"] = Time.get_unix_time_from_system()
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
	var was_expanded = bool(current_district_expanded.get(key, false))
	for existing_key in current_district_expanded.keys():
		current_district_expanded[existing_key] = false
	current_district_expanded[key] = not was_expanded
	show_page("buildings")

func toggle_storage_section(resource_id):
	var key = str(resource_id)
	var was_expanded = bool(storage_section_expanded.get(key, false))
	for existing_key in storage_section_expanded.keys():
		storage_section_expanded[existing_key] = false
	storage_section_expanded[key] = not was_expanded
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
	mission_target_building_id = ""
	mission_target_building_button = null
	match str(mission_id):
		"daily_build":
			target_page = "buildings"
		"daily_land":
			target_page = "transport"
		"daily_hire", "daily_population", "daily_satisfaction":
			target_page = "citizens"
		"daily_export":
			target_page = "transport"
		"daily_profit":
			target_page = "buildings"
			selected_building_category = "کسب‌وکارها"
		"daily_day":
			target_page = "home"
		"buy_land_tutorial":
			target_page = "transport"
		"build_house_tutorial":
			target_page = "buildings"
			selected_building_category = "خانه‌ها"
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

	# مأموریت‌های ساخت‌وساز را به کارت دقیق همان ساختمان هدایت کن.
	match str(mission_id):
		"build_house_tutorial": mission_target_building_id = "small_house"
		"build_farm_tutorial": mission_target_building_id = "farm"
		"market_tutorial": mission_target_building_id = "mineral_market"
		"main_water", "side_water": mission_target_building_id = "water_tower"
		"main_power", "side_power": mission_target_building_id = "power_station"
		"main_school", "side_school": mission_target_building_id = "school"
		"main_clinic", "side_clinic": mission_target_building_id = "clinic"
		"main_wood", "side_wood": mission_target_building_id = "woodcutter"
		"main_stone", "side_stone_mine": mission_target_building_id = "stone_mine"
		"main_sawmill", "side_sawmill": mission_target_building_id = "sawmill"
		"main_carpenter", "side_carpenter": mission_target_building_id = "carpenter"
		"main_city_bank", "side_bank": mission_target_building_id = "municipal_bank"
		"main_central_bank": mission_target_building_id = "central_bank"
		"side_sewage": mission_target_building_id = "sewage_plant"
		"side_waste": mission_target_building_id = "waste_facility"
		"side_park": mission_target_building_id = "small_park"
		"side_playground": mission_target_building_id = "playground"
		"side_sports": mission_target_building_id = "sports_center"
		"side_hospital": mission_target_building_id = "hospital"
		"side_police": mission_target_building_id = "police_station"
		"side_fire": mission_target_building_id = "fire_station"
		"side_university": mission_target_building_id = "university"
		"side_cultural": mission_target_building_id = "cultural_center"
		"side_iron_mine": mission_target_building_id = "iron_mine"
		"side_fish_lake", "side_fishing_dock": mission_target_building_id = "fishing_dock"
		"side_fish_market": mission_target_building_id = "fish_market"
		"side_fish_processing": mission_target_building_id = "fish_processing_plant"
		"side_grocery": mission_target_building_id = "grocery_store"
		"side_bakery": mission_target_building_id = "bakery"
		"side_restaurant": mission_target_building_id = "restaurant"
		"side_office": mission_target_building_id = "office"

	if mission_target_building_id != "":
		target_page = "buildings"
		var target_definition = game.get_building_definitions().get(mission_target_building_id, {})
		selected_building_category = "ماهیگیری" if mission_target_building_id in ["fish_lake", "fishing_dock", "fish_market", "fish_processing_plant"] else str(target_definition.get("category", ""))
	if target_page == "buildings":
		if selected_building_category == "خانه‌ها":
			selected_building_group = "مسکونی"
		elif selected_building_category == "انبارها":
			selected_building_group = "انبارها"
		elif selected_building_category in ["کشاورزی","ماهیگیری","معادن","کارخانه‌ها","کسب‌وکارها"]:
			selected_building_group = "اقتصادی"
		elif selected_building_category in ["خدمات شهری","تفریح و فرهنگ"]:
			selected_building_group = "عمومی"
		elif selected_building_category == "":
			selected_building_group = ""
	show_page(target_page)
	if game_scroll_container != null and is_instance_valid(game_scroll_container):
		game_scroll_container.scroll_vertical = 0
		if mission_target_building_id != "":
			call_deferred("_scroll_to_mission_target_building")
	_show_message("به ساختمان موردنیاز این مأموریت رفتی.")

func _scroll_to_mission_target_building():
	if game_scroll_container == null or not is_instance_valid(game_scroll_container):
		return
	if mission_target_building_button == null or not is_instance_valid(mission_target_building_button):
		return
	var target_y = mission_target_building_button.get_global_position().y - game_scroll_container.get_global_position().y + game_scroll_container.scroll_vertical
	game_scroll_container.scroll_vertical = max(0, int(target_y - 24))

func claim_login_reward():
	var result = game.claim_login_reward()
	if bool(result.get("ok", false)):
		audio_manager.play_sfx("reward")
	show_page("home")
	_show_message(str(result.message))

func resolve_resident_request(request_id, accepted):
	var result = game.resolve_resident_request(int(request_id),bool(accepted))
	show_page("citizens")
	_show_message(str(result.message))

func go_to_report_solution(issue_key, service_need):
	var building_id = ""
	match str(issue_key):
		"unemployed", "low_wallet":
			building_id = "office"
	match str(service_need):
		"food": building_id = "grocery_store"
		"water": building_id = "water_tower"
		"power": building_id = "power_station"
		"health": building_id = "clinic"
		"education": building_id = "school"
		"safety": building_id = "police_station"
		"leisure": building_id = "small_park"
		"sanitation": building_id = "waste_facility"
	if building_id == "":
		_show_message("برای این گزارش هنوز ساختمان مشخصی تعریف نشده است.")
		return
	var definition = game.get_building_definitions().get(building_id, {})
	if definition.is_empty():
		_show_message("ساختمان پیشنهادی این گزارش در فهرست ساخت‌وساز پیدا نشد.")
		return
	mission_target_building_id = building_id
	selected_building_category = str(definition.get("category", ""))
	if selected_building_category == "خانه‌ها":
		selected_building_group = "مسکونی"
	elif selected_building_category == "انبارها":
		selected_building_group = "انبارها"
	elif selected_building_category in ["کشاورزی", "ماهیگیری", "معادن", "کارخانه‌ها", "کسب‌وکارها"]:
		selected_building_group = "اقتصادی"
	else:
		selected_building_group = "عمومی"
	show_page("buildings")
	if game_scroll_container != null and is_instance_valid(game_scroll_container):
		game_scroll_container.scroll_vertical = 0
		call_deferred("_scroll_to_mission_target_building")
	_show_message("ساختمان پیشنهادی برای حل مشکل شهروندان را باز کردم.")

func go_to_resident_request_building(building_id):
	var definition = game.get_building_definitions().get(str(building_id),{})
	selected_building_category = str(definition.get("category","خدمات شهری"))
	if selected_building_category == "خانه‌ها":
		selected_building_group = "مسکونی"
	elif selected_building_category == "انبارها":
		selected_building_group = "انبارها"
	elif selected_building_category in ["کشاورزی","ماهیگیری","معادن","کارخانه‌ها","کسب‌وکارها"]:
		selected_building_group = "اقتصادی"
	else:
		selected_building_group = "عمومی"
	show_page("buildings")
	_show_message("دسته ساختمان پیشنهادی شهروندان باز شد.")


func resolve_city_decision(option_id):
	var result = game.resolve_city_decision(str(option_id))
	show_page("home")
	_show_message(str(result.message))

func claim_mystery_reward():
	var result = game.claim_mystery_reward()
	if bool(result.get("ok", false)):
		audio_manager.play_sfx("reward")
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
	if bool(result.get("ok", false)):
		audio_manager.play_sfx("reward")
	show_page("progress")
	_show_message(str(result.message))

func _add_daily_claim_button(parent, mission_id):
	var claim_button = Button.new()
	claim_button.text = PersianText.reshaper("🎁 دریافت جایزه")
	claim_button.custom_minimum_size = Vector2(0, 48 if get_viewport_rect().size.x < 900 else 42)
	claim_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(claim_button, 17)
	_style_button(claim_button, false)
	claim_button.connect("pressed", Callable(self, "claim_daily_mission").bind(mission_id))
	parent.add_child(claim_button)

func claim_daily_mission(mission_id):
	var result = game.claim_daily_mission(str(mission_id))
	if bool(result.get("ok", false)):
		audio_manager.play_sfx("reward")
	show_page("missions")
	_show_message(result.message)

func claim_mission(index):
	var result = game.claim_mission(index)
	if bool(result.get("ok", false)):
		audio_manager.play_sfx("reward")
	show_page("missions")
	_show_message(result.message)

func save_now():
	var ok = game.save_game()
	_show_message("شهر ذخیره شد." if ok else "ذخیره‌سازی ناموفق بود.")