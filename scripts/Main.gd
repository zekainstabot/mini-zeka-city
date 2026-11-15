extends Control

const EngineScript = preload("res://scripts/GameEngine.gd")
const PersianText = preload("res://scripts/PersianText.gd")
const AudioManagerScript = preload("res://scripts/AudioManager.gd")
const MainUITheme = preload("res://scripts/MainUITheme.gd")
const HelpPageBuilder = preload("res://scripts/HelpPageBuilder.gd")
const AudioSettingsPage = preload("res://scripts/AudioSettingsPage.gd")
const CitizensPage = preload("res://scripts/CitizensPage.gd")
const CityReportPage = preload("res://scripts/CityReportPage.gd")
const BankPage = preload("res://scripts/BankPage.gd")
const MunicipalityPage = preload("res://scripts/MunicipalityPage.gd")
const PrivateEconomyPage = preload("res://scripts/PrivateEconomyPage.gd")
const CommercePage = preload("res://scripts/CommercePage.gd")
const TransportPage = preload("res://scripts/TransportPage.gd")
const ImportsPage = preload("res://scripts/ImportsPage.gd")
const HomePage = preload("res://scripts/HomePage.gd")
const BuildingsPage = preload("res://scripts/BuildingsPage.gd")
const StoragePage = preload("res://scripts/StoragePage.gd")
const RankingPage = preload("res://scripts/RankingPage.gd")
const ProgressPage = preload("res://scripts/ProgressPage.gd")
const MissionsPage = preload("res://scripts/MissionsPage.gd")
const CityDashboardBuilder = preload("res://scripts/CityDashboardBuilder.gd")
const OfflineProgressController = preload("res://scripts/OfflineProgressController.gd")
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
var city_name_center_container = null
var city_name_keyboard_height = -1
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
var clock_displayed_second = -1
var construction_check_accumulator = 0.0
var storage_automation_accumulator = 0.0
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
var mission_navigation_button = null
var mission_navigation_title = ""
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
var daily_reward_layer = null
var daily_reward_button = null
var help_previous_page = "home"
var help_scroll_original_index = 5
var startup_loading_layer = null
var startup_loading_bar = null
var startup_loading_label = null
var startup_loading_percent = null
var startup_tip_label = null
var startup_tip_timer = null
var startup_tip_index = -1

func _on_ui_node_added(node):
	# Enforce one alignment rule for every text button, including buttons
	# created later by page builders, dialogs, popups, and overlays.
	if node is Button:
		node.alignment = HORIZONTAL_ALIGNMENT_CENTER

func _center_existing_button_texts(node):
	if node is Button:
		node.alignment = HORIZONTAL_ALIGNMENT_CENTER
	for child in node.get_children():
		_center_existing_button_texts(child)

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
	_update_city_name_keyboard_position()
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
	storage_automation_accumulator += delta
	if storage_automation_accumulator >= 60.0:
		storage_automation_accumulator = fmod(storage_automation_accumulator, 60.0)
		var storage_changed = false
		for resource_id in game.get_resource_definitions().keys():
			var storage_result = game.apply_storage_rule(str(resource_id), false)
			if bool(storage_result.get("ok", false)) and (str(storage_result.get("message","")).begins_with("خرید انجام شد:") or str(storage_result.get("message","")).begins_with("فروش ")):
				storage_changed = true
		if storage_changed and current_page == "storage":
			show_page("storage")
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
	# The game clock changes once per second; do not reshape and assign the same label every frame.
	var displayed_second = int(floor(clock_cycle_seconds))
	if displayed_second != clock_displayed_second:
		clock_displayed_second = displayed_second
		if clock_label != null and is_instance_valid(clock_label):
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
	return OfflineProgressController._apply_offline_progress(self)


func _show_offline_summary():
	return OfflineProgressController._show_offline_summary(self)


func _close_offline_summary():
	return OfflineProgressController._close_offline_summary(self)


func _claim_offline_income():
	return OfflineProgressController._claim_offline_income(self)


func _notification(what):
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and game != null:
		_handle_device_back()
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST and game != null:
		game.state["clock_last_unix"] = Time.get_unix_time_from_system()
		game.state["clock_cycle_seconds"] = int(clock_cycle_seconds)
		game.save_game()

func _ready():
	# Apply centered text to every Button in the scene tree, now and whenever
	# any game page or overlay creates additional buttons.
	get_tree().node_added.connect(_on_ui_node_added)
	_center_existing_button_texts(self)
	# Show a lightweight loading screen before doing any synchronous startup work.
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	_create_startup_loading_screen()
	await _set_startup_progress(3, "آماده‌سازی محیط بازی...")

	_load_ui_font()
	await _set_startup_progress(12, "بارگذاری فونت و رابط فارسی...")

	audio_manager = AudioManagerScript.new()
	add_child(audio_manager)
	await _set_startup_progress(20, "آماده‌سازی صداها...")

	game = EngineScript.new()
	await _set_startup_progress(34, "آماده‌سازی اطلاعات شهر...")

	var has_existing_save = game.load_game()
	if not has_existing_save:
		game.new_game()
		# First launch starts in portrait. Later launches always use the saved orientation.
		game.state["screen_orientation"] = "portrait"
		game.save_game()
	await _set_startup_progress(52, "بارگذاری اطلاعات و ذخیره شهر...")

	var saved_orientation = str(game.state.get("screen_orientation", "portrait"))
	if saved_orientation not in ["auto", "portrait", "landscape"]:
		saved_orientation = "portrait"
		game.state["screen_orientation"] = saved_orientation
		game.save_game()
	_apply_screen_orientation(saved_orientation)
	game.register_login_today()
	await _set_startup_progress(63, "به‌روزرسانی وضعیت روزانه...")

	game.get_daily_missions()
	game.get_weekly_challenge()
	last_activity_ticks = Time.get_ticks_msec()
	_apply_offline_progress()
	clock_cycle_seconds = float(game.state.get("clock_cycle_seconds", 0))
	last_audio_night_mode = clock_cycle_seconds >= 420.0
	# Configure audio without generating long PCM streams during the loading screen.
	audio_manager.configure_startup_night_mode(last_audio_night_mode)
	set_process(true)
	await _set_startup_progress(76, "ساخت صفحه‌های بازی...")

	_build_ui()
	last_layout_viewport_size = Vector2.ZERO
	_apply_responsive_layout()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	await _set_startup_progress(90, "آماده‌سازی شهر و منوها...")

	show_page("home")
	if str(game.state.get("city_name", "")).strip_edges() == "":
		_open_city_name_setup(true)
	else:
		_show_offline_summary()
	await _set_startup_progress(100, "آماده‌ای! خوش اومدی به مینی زکا سیتی")
	_finish_startup_loading()
	# Start ambient audio only after the first playable frame; avoid generating it twice.
	audio_manager.call_deferred("start_ambience")


func _create_startup_loading_screen():
	var layer = CanvasLayer.new()
	layer.name = "StartupLoadingLayer"
	layer.layer = 200
	add_child(layer)
	startup_loading_layer = layer

	var background = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("#091522")
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(background)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24
	center.offset_right = -24
	# Shift the card 14 px downward so its title does not sit beneath the camera cutout.
	center.offset_top = 38
	center.offset_bottom = -10
	layer.add_child(center)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 285)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color("#14283b")
	card_style.border_color = Color("#25617e")
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(22)
	card_style.content_margin_left = 24
	card_style.content_margin_right = 24
	card_style.content_margin_top = 26
	card_style.content_margin_bottom = 26
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	card.add_child(layout)

	var brand = Label.new()
	brand.text = "✦  ZEKAMEDIAFA  ✦"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(brand, 14)
	brand.add_theme_color_override("font_color", Color("#7dd3fc"))
	layout.add_child(brand)

	var title = Label.new()
	title.text = "مینی زکا سیتی"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(title, 27)
	title.add_theme_color_override("font_color", Color("#ffffff"))
	layout.add_child(title)

	startup_loading_label = Label.new()
	startup_loading_label.text = "در حال آماده‌سازی بازی..."
	startup_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(startup_loading_label, 15)
	startup_loading_label.add_theme_color_override("font_color", Color("#cbd5e1"))
	layout.add_child(startup_loading_label)

	startup_loading_bar = ProgressBar.new()
	startup_loading_bar.min_value = 0
	startup_loading_bar.max_value = 100
	startup_loading_bar.value = 0
	startup_loading_bar.show_percentage = false
	startup_loading_bar.custom_minimum_size = Vector2(0, 17)
	var track = StyleBoxFlat.new()
	track.bg_color = Color("#26394b")
	track.set_corner_radius_all(9)
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color("#38bdf8")
	fill.set_corner_radius_all(9)
	startup_loading_bar.add_theme_stylebox_override("background", track)
	startup_loading_bar.add_theme_stylebox_override("fill", fill)
	layout.add_child(startup_loading_bar)

	startup_loading_percent = Label.new()
	startup_loading_percent.text = "۰٪"
	startup_loading_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(startup_loading_percent, 17)
	startup_loading_percent.add_theme_color_override("font_color", Color("#7dd3fc"))
	layout.add_child(startup_loading_percent)

	var tip_heading = Label.new()
	tip_heading.text = "💡 نکته‌ای برای شهرت"
	tip_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(tip_heading, 14)
	tip_heading.add_theme_color_override("font_color", Color("#fbbf24"))
	layout.add_child(tip_heading)

	startup_tip_label = Label.new()
	startup_tip_label.text = ""
	startup_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	startup_tip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	startup_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	startup_tip_label.custom_minimum_size = Vector2(0, 48)
	_apply_font(startup_tip_label, 14)
	startup_tip_label.add_theme_color_override("font_color", Color("#dbeafe"))
	layout.add_child(startup_tip_label)
	_show_next_startup_tip()

	startup_tip_timer = Timer.new()
	startup_tip_timer.wait_time = 4.0
	startup_tip_timer.one_shot = false
	startup_tip_timer.timeout.connect(_show_next_startup_tip)
	layer.add_child(startup_tip_timer)
	startup_tip_timer.start()


func _show_next_startup_tip():
	if startup_tip_label == null or not is_instance_valid(startup_tip_label):
		return
	var tips = [
		"با اسلایدر بازار، مقدار خرید و فروش هر کالا رو دقیق انتخاب کن.",
		"برای انبار، موجودی هدف تعیین کن تا مازاد فروخته و کمبود جبران بشه.",
		"مدیریت پول شهر مهمه؛ قبل از خرید، موجودی خزانه رو بررسی کن.",
		"برای توسعه محله‌های بعدی، سطح جاده موردنیاز رو ارتقا بده.",
		"از بخش خدمات شهری، وضعیت پوشش خدمات و زیرساخت‌ها رو بررسی کن.",
		"تولید داخلی می‌تونه نیاز شهر رو تأمین کنه؛ ظرفیت انبار رو هم در نظر بگیر.",
		"با تکمیل مأموریت‌ها و چالش‌ها، پاداش‌های شهر رو دریافت کن.",
		"در بازار، صادرات راهی برای فروش کالاهای مازاد شهره."
	]
	if tips.size() <= 1:
		startup_tip_index = 0
	else:
		var next_index = randi_range(0, tips.size() - 1)
		while next_index == startup_tip_index:
			next_index = randi_range(0, tips.size() - 1)
		startup_tip_index = next_index
	startup_tip_label.text = PersianText.reshaper(tips[startup_tip_index])


func _set_startup_progress(value: int, message: String):
	var safe_value = clampi(value, 0, 100)
	if startup_loading_bar != null and is_instance_valid(startup_loading_bar):
		startup_loading_bar.value = safe_value
	if startup_loading_label != null and is_instance_valid(startup_loading_label):
		startup_loading_label.text = PersianText.reshaper(message)
	if startup_loading_percent != null and is_instance_valid(startup_loading_percent):
		startup_loading_percent.text = "%d٪" % safe_value
	# Yield so the updated progress is actually drawn before the next stage runs.
	await get_tree().process_frame


func _finish_startup_loading():
	if startup_loading_layer != null and is_instance_valid(startup_loading_layer):
		startup_loading_layer.queue_free()
	startup_loading_layer = null
	startup_loading_bar = null
	startup_loading_label = null
	startup_loading_percent = null
	startup_tip_label = null
	startup_tip_timer = null



func _update_city_name_keyboard_position():
	if city_name_center_container == null or not is_instance_valid(city_name_center_container):
		return
	var keyboard_height = DisplayServer.virtual_keyboard_get_height()
	if keyboard_height == city_name_keyboard_height:
		return
	city_name_keyboard_height = keyboard_height
	# Move the complete name-entry card upward while the Android keyboard is open.
	# The capped offset keeps the title and action buttons visible on short screens.
	var upward_shift = minf(float(keyboard_height) * 0.35, 140.0) if keyboard_height > 0 else 0.0
	# Keep the city-name card slightly lower to clear the phone camera/notch area.
	city_name_center_container.offset_top = 38.0 - upward_shift
	city_name_center_container.offset_bottom = -10.0 - upward_shift


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
	center.offset_left = 24
	center.offset_right = -24
	center.offset_top = 24
	center.offset_bottom = -24
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	city_name_center_container = center
	city_name_keyboard_height = -1
	city_name_overlay.add_child(center)
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(max(0.0, min(520.0, get_viewport_rect().size.x - 48.0)), 0)
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
	if city_name_setup_first_time:
		var brand_badge = PanelContainer.new()
		brand_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var brand_style = StyleBoxFlat.new()
		brand_style.bg_color = Color("#102f46")
		brand_style.border_color = Color("#38bdf8")
		brand_style.set_border_width_all(1)
		brand_style.set_corner_radius_all(18)
		brand_style.content_margin_left = 18
		brand_style.content_margin_right = 18
		brand_style.content_margin_top = 7
		brand_style.content_margin_bottom = 7
		brand_badge.add_theme_stylebox_override("panel", brand_style)
		var brand_text = Label.new()
		brand_text.text = "✦  zekamediafa  ✦"
		brand_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_apply_font(brand_text, 14)
		brand_text.add_theme_color_override("font_color", Color("#7dd3fc"))
		brand_badge.add_child(brand_text)
		layout.add_child(brand_badge)
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
	city_name_center_container = null
	city_name_keyboard_height = -1


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
	var short_screen = viewport_size.y < 500.0
	var horizontal_margin = 18.0 if narrow else (22.0 if compact else 28.0)
	var top_margin = 18.0 if short_screen else (40.0 if compact else 36.0)
	var bottom_margin = 18.0 if short_screen else (28.0 if compact else 26.0)
	main_layout.offset_left = horizontal_margin
	main_layout.offset_right = -horizontal_margin
	main_layout.offset_top = top_margin
	main_layout.offset_bottom = -bottom_margin
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
	var initial_viewport_size = get_viewport_rect().size
	var compact_layout = initial_viewport_size.x < 900.0
	var narrow_layout = initial_viewport_size.x < 380.0
	var short_screen = initial_viewport_size.y < 500.0
	var horizontal_margin = 18.0 if narrow_layout else (22.0 if compact_layout else 28.0)
	var top_margin = 18.0 if short_screen else (40.0 if compact_layout else 36.0)
	var bottom_margin = 18.0 if short_screen else (28.0 if compact_layout else 26.0)
	root.offset_left = horizontal_margin
	root.offset_top = top_margin
	root.offset_right = -horizontal_margin
	root.offset_bottom = -bottom_margin
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

	# Move the existing controls beside the daily calendar without changing
	# their callbacks or modal behavior. Keep them as floating top-level controls.
	menu_row.remove_child(menu_button)
	menu_row.remove_child(help_button)
	menu_row.visible = false
	menu_button.anchor_left = 0.0
	menu_button.anchor_top = 0.0
	menu_button.anchor_right = 0.0
	menu_button.anchor_bottom = 0.0
	menu_button.position = Vector2(105, 48)
	menu_button.z_index = 15
	add_child(menu_button)
	help_button.anchor_left = 0.0
	help_button.anchor_top = 0.0
	help_button.anchor_right = 0.0
	help_button.anchor_bottom = 0.0
	help_button.position = Vector2(181, 50)
	help_button.z_index = 15
	add_child(help_button)
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
	help_card.custom_minimum_size = Vector2(min(560.0, initial_viewport_size.x - 40.0), min(760.0, get_viewport_rect().size.y - 40.0))
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
	menu_card.custom_minimum_size = Vector2(min(440.0, initial_viewport_size.x - 56.0), 0)
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
	for item in [{"t":"شهر من","p":"home"},{"t":"ساختمان‌ها","p":"buildings"},{"t":"شهروندان","p":"citizens"},{"t":"بانک و امور مالی","p":"bank"},{"t":"شهرداری","p":"municipality"},{"t":"اقتصاد خصوصی","p":"private_economy"},{"t":"بازار و تجارت","p":"commerce"},{"t":"توسعه شهر","p":"transport"},{"t":"انبار","p":"storage"},{"t":"گزارش","p":"report"},{"t":"پیشرفت و مأموریت‌ها","p":"missions"},{"t":"🏆 رتبه‌بندی","p":"ranking"}]:
		var nav_item = VBoxContainer.new()
		nav_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav_item.add_theme_constant_override("separation", 2)
		var nav_title = str(item.t)
		if compact_layout:
			match str(item.p):
				"buildings": nav_title = "ساختمان"
				"bank": nav_title = "بانک"
				"private_economy": nav_title = "اقتصاد"
				"commerce": nav_title = "بازار"
				"transport": nav_title = "توسعه شهر"
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
		if str(item.p) == "ranking":
			# Keep ranking visually consistent with the other navigation buttons.
			b.text = PersianText.reshaper("رتبه‌بندی شهرها")
			b.alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.text_direction = Control.TEXT_DIRECTION_RTL
		if str(item.p) == "missions":
			b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			b.text_direction = Control.TEXT_DIRECTION_RTL
			mission_navigation_button = b
			mission_navigation_title = nav_title
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
	_build_daily_reward_calendar_button()

func _build_daily_reward_calendar_button():
	daily_reward_button = Button.new()
	daily_reward_button.name = "DailyRewardCalendarButton"
	daily_reward_button.text = "📅"
	daily_reward_button.tooltip_text = "تقویم جایزه‌های ورود"
	daily_reward_button.custom_minimum_size = Vector2(66, 62)
	# Keep the calendar near the upper-left, slightly inset and visually light.
	daily_reward_button.layout_direction = Control.LAYOUT_DIRECTION_LTR
	daily_reward_button.anchor_left = 0.0
	daily_reward_button.anchor_top = 0.0
	daily_reward_button.anchor_right = 0.0
	daily_reward_button.anchor_bottom = 0.0
	daily_reward_button.position = Vector2(30, 48)
	daily_reward_button.z_index = 15
	_apply_font(daily_reward_button, 30)
	_style_button(daily_reward_button, false)
	var transparent_calendar_style = StyleBoxEmpty.new()
	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		daily_reward_button.add_theme_stylebox_override(style_name, transparent_calendar_style)
	daily_reward_button.pressed.connect(_open_daily_reward_calendar)
	add_child(daily_reward_button)

func _open_daily_reward_calendar():
	if daily_reward_layer != null and is_instance_valid(daily_reward_layer):
		daily_reward_layer.queue_free()
	daily_reward_layer = CanvasLayer.new()
	daily_reward_layer.name = "DailyRewardCalendarLayer"
	daily_reward_layer.layer = 80
	add_child(daily_reward_layer)
	var backdrop = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.035, 0.065, 0.88)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	daily_reward_layer.add_child(backdrop)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 14
	center.offset_right = -14
	center.offset_top = 18
	center.offset_bottom = -18
	backdrop.add_child(center)
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(min(540.0, get_viewport_rect().size.x - 36.0), 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color("#14243a")
	card_style.border_color = Color("#fbbf24")
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(22)
	card_style.content_margin_left = 14
	card_style.content_margin_right = 14
	card_style.content_margin_top = 16
	card_style.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 9)
	card.add_child(layout)
	var header = HBoxContainer.new()
	layout.add_child(header)
	var title = Label.new()
	title.text = PersianText.reshaper("🎁 تقویم جایزه ورود")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(title, 21)
	title.add_theme_color_override("font_color", Color("#fef3c7"))
	header.add_child(title)
	var close_button = Button.new()
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(42, 40)
	_apply_font(close_button, 21)
	_style_button(close_button, false)
	close_button.pressed.connect(_close_daily_reward_calendar)
	header.add_child(close_button)
	var status = game.get_login_reward_status()
	var intro_text = "هر جایزه ۲۴ ساعت پس از دریافت قبلی باز می‌شود و تا ۲۴ ساعت فرصت دریافتش را داری؛ اگر این مهلت را از دست بدهی، زنجیره از روز اول شروع می‌شود."
	var intro = Label.new()
	intro.text = PersianText.reshaper(intro_text)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(intro, 13)
	intro.add_theme_color_override("font_color", Color("#cbd5e1"))
	layout.add_child(intro)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, min(500.0, max(250.0, get_viewport_rect().size.y - 260.0)))
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	# Calendar-style layout: seven equal date cells, four above and three below.
	var days_grid = GridContainer.new()
	days_grid.columns = 4
	days_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	days_grid.add_theme_constant_override("h_separation", 6)
	days_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(days_grid)
	var rewards = game.get_login_reward_calendar()
	var next_day = int(status.next_day)
	var streak = int(status.streak)
	for reward_data in rewards:
		var day = int(reward_data.day)
		var claimed = (day == 7) if streak == 7 and next_day == 1 else (day <= streak)
		var is_next = day == next_day
		var tile = PanelContainer.new()
		tile.custom_minimum_size = Vector2(0, 132)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tile_style = StyleBoxFlat.new()
		tile_style.bg_color = Color("#183b35") if claimed else (Color("#4a3715") if is_next and bool(status.can_claim) else Color("#1e293b"))
		tile_style.border_color = Color("#fbbf24") if day == 7 else (Color("#34d399") if claimed else (Color("#fbbf24") if is_next else Color("#64748b")))
		tile_style.set_border_width_all(2 if day == 7 or is_next else 1)
		tile_style.set_corner_radius_all(9)
		tile_style.content_margin_left = 3
		tile_style.content_margin_right = 3
		tile_style.content_margin_top = 5
		tile_style.content_margin_bottom = 5
		tile.add_theme_stylebox_override("panel", tile_style)
		days_grid.add_child(tile)
		var tile_layout = VBoxContainer.new()
		tile_layout.alignment = BoxContainer.ALIGNMENT_CENTER
		tile_layout.add_theme_constant_override("separation", 3)
		tile.add_child(tile_layout)
		var date_number = Label.new()
		date_number.text = PersianText.reshaper("%d" % day)
		date_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_apply_font(date_number, 24)
		date_number.add_theme_color_override("font_color", Color("#fde68a") if day == 7 else Color("#f8fafc"))
		tile_layout.add_child(date_number)
		var day_caption = Label.new()
		day_caption.text = PersianText.reshaper("روز %d%s" % [day, " 👑" if day == 7 else ""])
		day_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_apply_font(day_caption, 10)
		day_caption.add_theme_color_override("font_color", Color("#cbd5e1"))
		tile_layout.add_child(day_caption)
		var separator = HSeparator.new()
		separator.add_theme_color_override("color", Color("#64748b"))
		tile_layout.add_child(separator)
		var prize_label = Label.new()
		var item_text = "\n🏅 " + str(reward_data.get("item", "")) if reward_data.has("item") else ""
		prize_label.text = PersianText.reshaper("%d سکه\n%d XP%s" % [int(reward_data.coins), int(reward_data.xp), item_text])
		prize_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prize_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		prize_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_apply_font(prize_label, 11)
		prize_label.add_theme_color_override("font_color", Color("#ffffff"))
		tile_layout.add_child(prize_label)
		var state_label = Label.new()
		if claimed:
			state_label.text = "✓"
		elif is_next and bool(status.can_claim):
			state_label.text = "🎁"
		elif is_next:
			var remain = int(status.seconds_remaining)
			state_label.text = "%02d:%02d" % [int(remain / 3600), int((remain % 3600) / 60)]
		else:
			state_label.text = "🔒"
		state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_apply_font(state_label, 13)
		tile_layout.add_child(state_label)
	var footer = Label.new()
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(footer, 14)
	footer.add_theme_color_override("font_color", Color("#a7f3d0"))
	if bool(status.can_claim):
		footer.text = PersianText.reshaper("جایزه روز %d آماده دریافت است!" % next_day)
	else:
		var remain_seconds = int(status.seconds_remaining)
		footer.text = PersianText.reshaper("جایزه بعدی تا %d ساعت و %d دقیقه دیگر باز می‌شود." % [int(remain_seconds / 3600), int((remain_seconds % 3600) / 60)])
	layout.add_child(footer)
	var claim_button = Button.new()
	claim_button.text = PersianText.reshaper("🎁 دریافت جایزه روز %d" % next_day if bool(status.can_claim) else "⏳ منتظر جایزه بعدی")
	claim_button.custom_minimum_size = Vector2(0, 52)
	_apply_font(claim_button, 18)
	_style_button(claim_button, true)
	claim_button.disabled = not bool(status.can_claim)
	claim_button.pressed.connect(claim_login_reward)
	layout.add_child(claim_button)

func _close_daily_reward_calendar():
	if daily_reward_layer != null and is_instance_valid(daily_reward_layer):
		daily_reward_layer.queue_free()
	daily_reward_layer = null

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
	if game == null:
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

	if mission_navigation_button != null and is_instance_valid(mission_navigation_button):
		mission_navigation_button.text = PersianText.reshaper(mission_navigation_title + (" 🎁" if ready_count > 0 else ""))

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
	# Reset the game exactly like a first launch: create a blank city state,
	# persist it so an interrupted setup is shown again on the next launch,
	# then require the player to choose a name before entering the city.
	_close_game_menu()
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
	_open_city_name_setup(true)

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
	# Let wrapped Persian text determine its own height instead of clipping to a fixed row.
	label.custom_minimum_size = Vector2.ZERO
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
	if page == "home":
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
			HomePage.build(self, s)
		"buildings":
			BuildingsPage.build(self, s)
		"citizens":
			CitizensPage.build(self, s)
		"bank":
			BankPage.build(self, s)
		"municipality":
			MunicipalityPage.build(self, s)
		"private_economy":
			PrivateEconomyPage.build(self, s)
		"commerce":
			CommercePage.build(self, s)
		"transport":
			TransportPage.build(self, s)
		"imports":
			ImportsPage.build(self, s)
		"storage":
			StoragePage.build(self, s)
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
			_add_help_section("تقویم جایزه ورود", "از آیکون تقویم گوشه بالای صفحه، هر ۷ جایزه را ببین و جایزه آماده را دریافت کن. هر جایزه ۲۴ ساعت پس از دریافت قبلی باز می‌شود؛ اگر ۴۸ ساعت بگذرد و جایزه بعدی را نگیری، زنجیره از روز اول شروع می‌شود. روز هفتم صندوق طلایی ویژه دارد.", "home")
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
			_add_label("• جایزه مأموریت و درآمد آفلاین را در صورت آماده بودن دریافت کن؛ هدیه ورود در تقویم است.", 16)
			_add_label("• هر روز گزارش شهر، رویداد هفتگی و رتبه رقبا را بررسی کن.", 16)
			_add_button("🏙️ حالا برگردیم به شهر!", self, "return_home_from_menu")


		"ranking":
			RankingPage.build(self, s)
		"progress":
			ProgressPage.build(self, s)
		"missions":
			MissionsPage.build(self, s)

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
	return CityDashboardBuilder._add_home_services_panel(self, city_state)


func _add_service_metric_card(parent, title_text, coverage, need, building_count, compact):
	return CityDashboardBuilder._add_service_metric_card(self, parent, title_text, coverage, need, building_count, compact)


func _service_summary():
	return CityDashboardBuilder._service_summary(self)


func _needs_summary():
	return CityDashboardBuilder._needs_summary(self)


func _active_mine_count():
	return CityDashboardBuilder._active_mine_count(self)


func _sort_building_ids_by_unlock_priority(a, b):
	return CityDashboardBuilder._sort_building_ids_by_unlock_priority(self, a, b)


func _add_building_category_items(category):
	return CityDashboardBuilder._add_building_category_items(self, category)


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
	return CityDashboardBuilder._resource_summary(self)


func resolve_civic_request(request_id, approved):
	var result = game.resolve_civic_request(request_id, approved)
	show_page("municipality")
	_show_message(result.message)

func resolve_private_request(request_id, approved):
	var result = game.resolve_civic_request(request_id, approved)
	show_page("private_economy")
	_show_message(result.message)

func _add_policy_slider(title, current_value, minimum_value, maximum_value, step_value, method_name, unit_text):
	var group = VBoxContainer.new()
	group.add_theme_constant_override("separation", 5)
	group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(group)
	var title_label = Label.new()
	title_label.text = PersianText.reshaper(str(title))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title_label.text_direction = Control.TEXT_DIRECTION_RTL
	_apply_font(title_label, 16)
	group.add_child(title_label)
	var value_label = Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.text = PersianText.reshaper("%s %s" % [str(int(current_value)), str(unit_text)])
	_apply_font(value_label, 19)
	value_label.add_theme_color_override("font_color", Color("#f5d477"))
	group.add_child(value_label)
	var slider = HSlider.new()
	slider.min_value = float(minimum_value)
	slider.max_value = float(maximum_value)
	slider.step = float(step_value)
	slider.value = clampf(float(current_value), float(minimum_value), float(maximum_value))
	slider.custom_minimum_size = Vector2(0, 38)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group.add_child(slider)
	slider.value_changed.connect(func(value):
		value_label.text = PersianText.reshaper("%s %s" % [str(int(round(value))), str(unit_text)])
	)
	slider.drag_ended.connect(func(changed):
		if changed:
			var target_value = int(round(slider.value / float(step_value))) * int(step_value)
			var delta = target_value - int(current_value)
			if delta != 0:
				call(method_name, delta)
	)
	return slider

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
	var is_first_building_started = game.state.get("buildings", []).size() <= 1 and game.state.get("constructions", []).is_empty()
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
	if bool(result.get("ok", false)) and is_first_building_started:
		_show_temporary_message("💡 برای دیدن جزئیات، به بخش «شهر من» برو.", 4.0)

func _show_temporary_message(text, seconds=4.0):
	var shown_text = PersianText.reshaper(str(text))
	message_label.text = shown_text
	await get_tree().create_timer(float(seconds)).timeout
	if is_instance_valid(message_label) and message_label.text == shown_text:
		message_label.text = ""

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

func make_import_contract_from_slider(city_id, slider, days):
	make_import_contract(city_id, "wood", int(round(slider.value)), days)

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

func buy_item_from_slider(id, slider):
	buy_item(id, int(round(slider.value)))

func sell_item_from_slider(id, slider):
	sell_item(id, int(round(slider.value)))

func export_from_slider(city_id, resource_id, slider):
	export_to_city(city_id, resource_id, int(round(slider.value)))

func import_from_slider(city_id, resource_id, slider):
	import_from_city(city_id, resource_id, int(round(slider.value)))


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

func set_storage_target_slider(resource_id, value):
	var result = game.set_storage_target(str(resource_id), int(value))
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
	_close_daily_reward_calendar()
	show_page(current_page)
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