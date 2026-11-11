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
var touch_scroll_dragging = false
var restart_confirm_panel = null
var municipality_section_expanded = {"land":false,"tax":false,"requests":false,"properties":false,"projects":false}
var active_section_container = null

func _input(event):
	if game_scroll_container == null or not is_instance_valid(game_scroll_container):
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_scroll_active = game_scroll_container.get_global_rect().has_point(event.position)
			touch_scroll_start = event.position
			touch_scroll_last_y = event.position.y
			touch_scroll_dragging = false
		else:
			touch_scroll_active = false
			touch_scroll_dragging = false
	elif event is InputEventScreenDrag and touch_scroll_active:
		var distance = abs(event.position.y - touch_scroll_start.y)
		if distance > 8.0:
			touch_scroll_dragging = true
		if touch_scroll_dragging:
			var delta_y = event.position.y - touch_scroll_last_y
			var bar = game_scroll_container.get_v_scrollbar()
			var max_scroll = max(0.0, bar.max_value - bar.page)
			game_scroll_container.scroll_vertical = int(clamp(float(game_scroll_container.scroll_vertical) - delta_y * 1.6, 0.0, max_scroll))
		touch_scroll_last_y = event.position.y

func _process(delta):
	if game == null or game_paused:
		return
	clock_cycle_seconds += delta
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
		clock_label.text = PersianText.reshaper("%s | زمان باقی‌مانده: %02d:%02d" % [phase, int(phase_remaining / 60), phase_remaining % 60])
	if clock_save_accumulator >= 15.0:
		clock_save_accumulator = 0.0
		game.state["clock_last_unix"] = OS.get_unix_time()
		game.state["clock_cycle_seconds"] = int(clock_cycle_seconds)
		game.save_game()

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
			label.text = PersianText.reshaper("%s | زمان باقی‌مانده: %02d:%02d" % [str(project.name), int(seconds_left / 60), seconds_left % 60])

func _apply_offline_progress():
	var now = OS.get_unix_time()
	var last = int(game.state.get("clock_last_unix", now))
	var elapsed = max(0, now - last)
	var offline_days = min(10, int(floor(float(elapsed) / 3600.0)))
	for day_index in range(offline_days):
		game.end_day()
	game.state["clock_last_unix"] = now
	game.state["clock_cycle_seconds"] = int(game.state.get("clock_cycle_seconds", 0))
	game.save_game()

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
	_apply_offline_progress()
	clock_cycle_seconds = float(game.state.get("clock_cycle_seconds", 0))
	set_process(true)
	_build_ui()
	show_page("home")

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
	_style_button(menu_button, false)
	menu_row.add_child(menu_button)
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
	_style_button(restart_no_button, true)
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
	for item in [{"t":"شهر من","p":"home"},{"t":"ساختمان‌ها","p":"buildings"},{"t":"شهروندان","p":"citizens"},{"t":"شهرداری","p":"municipality"},{"t":"اقتصاد خصوصی","p":"private_economy"},{"t":"بازار و تجارت","p":"commerce"},{"t":"جاده و ناوگان","p":"transport"},{"t":"انبار","p":"storage"},{"t":"گزارش روز","p":"report"},{"t":"ماموریت‌ها","p":"missions"}]:
		var b = Button.new()
		b.text = PersianText.reshaper(item.t + "  ")
		b.rect_min_size = Vector2(0, 64 if compact_layout else 58)
		b.flat = false
		_apply_font(b, 21 if compact_layout else 18)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(b, true)
		b.connect("pressed", self, "show_page", [item.p])
		nav.add_child(b)
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
	level_status_label.text = PersianText.reshaper("سطح شهر  %d" % level)
	xp_progress_label.text = PersianText.reshaper("تجربه شهر: %d٪" % int(round(percent)))
	xp_progress_bar.max_value = required
	xp_progress_bar.value = min(xp, required)
	level_status_bar.value = 100

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
	ui_font.use_filter = true
	ui_font.use_mipmaps = false

func _apply_font(control, size=18):
	if ui_font == null:
		return
	var font = DynamicFont.new()
	font.font_data = ui_font.font_data
	font.use_filter = true
	font.use_mipmaps = false
	# Slightly larger glyphs and a subtle dark outline improve readability on mobile.
	font.size = int(size) + (3 if get_viewport_rect().size.x < 900 else 2)
	font.outline_size = 1
	font.outline_color = Color("#0b1220")
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
	var normal_color = Color("#fbbf24") if navigation else Color("#7c3aed")
	var hover_color = Color("#fde68a") if navigation else Color("#8b5cf6")
	var pressed_color = Color("#d97706") if navigation else Color("#5b21b6")
	button.add_stylebox_override("normal", _button_style(normal_color, Color("#ffffff") if navigation else Color("#c4b5fd")) )
	button.add_stylebox_override("hover", _button_style(hover_color, Color("#ffffff")))
	button.add_stylebox_override("focus", _button_style(hover_color, Color("#ffffff")))
	button.add_stylebox_override("pressed", _button_style(pressed_color, Color("#ffffff")))
	button.add_stylebox_override("disabled", _button_style(Color("#475569"), Color("#94a3b8")))
	button.add_color_override("font_color", Color("#111827") if navigation else Color("#ffffff"))
	button.add_color_override("font_color_focus", Color("#ffffff"))
	button.add_color_override("font_color_hover", Color("#111827") if navigation else Color("#ffffff"))
	button.add_color_override("font_color_pressed", Color("#ffffff"))
	button.add_color_override("font_color_disabled", Color("#f8fafc"))

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

func _add_button(text, target, callback, args=[]):
	var button = Button.new()
	button.text = PersianText.reshaper(text + "  ")
	button.rect_min_size = Vector2(0, 58 if get_viewport_rect().size.x < 900 else 50)
	_apply_font(button, 19 if get_viewport_rect().size.x < 900 else 17)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(button, false)
	button.connect("pressed", target, callback, args)
	var target = active_section_container if active_section_container != null else content
	target.add_child(button)
	return button

func _show_message(text):
	message_label.text = PersianText.reshaper(text)

func show_page(page):
	current_page = page
	_clear_content()
	_show_message("")
	var s = game.state
	_update_progress_hud()
	if page == "home" or page == "buildings":
		var active_constructions = game.get_construction_status()
		if active_constructions.size() > 0:
			_add_label("🏗️ پروژه‌های در حال ساخت", 19)
			for project in active_constructions:
				var seconds_left = int(project.remaining)
				var time_label = _add_label("%s | زمان باقی‌مانده: %02d:%02d" % [str(project.name), int(seconds_left / 60), seconds_left % 60], 16)
				construction_time_labels.append({"label":time_label,"name":str(project.name)})
	match page:
		"home":
			_add_label("وضعیت کلی شهر", 22)
			_add_label("روز %d  |  سطح شهر %d" % [s.day,s.level], 19)
			clock_label = _add_label("روز | زمان باقی‌مانده: 07:00", 18)
			_add_label("خزانه: %d / %d سکه  |  پول قفل‌شده: %d" % [s.money,game.get_treasury_capacity(),game.get_locked_money()], 20)
			_add_label("جمعیت: %d نفر  |  شاغل: %d  |  بیکار: %d" % [s.population,game.get_employed_count(),game.get_unemployed_count()], 19)
			_add_label("اعتبار شهر: %d  |  رضایت: %d/۱۰۰" % [s.reputation,int(s.get("satisfaction",50))], 18)

			var details_toggle = _add_button(("▼ " if home_city_details_expanded else "▶ ") + "خدمات و زیرساخت شهر", self, "toggle_home_city_details")
			if home_city_details_expanded:
				_add_label("پوشش خدمات: " + _service_summary(), 15)
				_add_label("نیازهای شهروندان: " + _needs_summary(), 15)
				_add_label("تعداد ساختمان‌ها: %d  |  ظرفیت انبار: %d" % [s.buildings.size(),game.get_storage_capacity()], 16)
				var central_bank_status = "فعال" if game.has_central_bank() else ("بازسازی تا %d روز دیگر" % int(s.get("central_bank_rebuild_days_left",0)) if int(s.get("central_bank_rebuild_days_left",0)) > 0 else "ندارد")
				_add_label("بانک مرکزی: %s  |  بانک شهری: %d" % [central_bank_status,game.get_building_count("municipal_bank")], 16)
				_add_label("درختان جنگل: %d از ۱۰۰  |  معادن فعال: %d" % [game.get_forest_tree_count(),_active_mine_count()], 16)

			var buildings_toggle = _add_button(("▼ " if home_buildings_expanded else "▶ ") + "ساختمان‌های ساخته‌شده", self, "toggle_home_buildings")
			if home_buildings_expanded:
				var home_categories = ["خانه‌ها","کشاورزی","معادن","کارخانه‌ها","کسب‌وکارها","خدمات شهری","تفریح و فرهنگ","انبارها","زیرساخت"]
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
			if demolish_panel_expanded:
				_add_label("ساختمان موردنظر را انتخاب کن:", 16)
				for home_id in game.get_building_definitions().keys():
					var home_count = game.get_building_count(home_id)
					if home_count <= 0:
						continue
					var home_data = game.get_building_definitions()[home_id]
					var home_button = _add_button("%s  |  تعداد: %d" % [str(home_data.name),home_count], self, "select_home_building", [home_id])
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
					if selected_home_building_id == "small_house" and selected_count <= 1:
						demolish_button.disabled = true
				else:
					_add_label("برای تخریب، ابتدا یک ساختمان را انتخاب کن.", 15)

			var economy_toggle = _add_button(("▼ " if home_economy_expanded else "▶ ") + "منابع و گزارش مالی", self, "toggle_home_economy")
			if home_economy_expanded:
				_add_label("منابع: " + _resource_summary(), 16)
				_add_label("ذخیره غذای شهر: %d واحد" % int(s.resources.get("food",0)), 16)
				var home_economy = s.get("last_economy", {})
				_add_label("آخرین تراز روزانه: %d سکه" % int(home_economy.get("net_cashflow",0)), 17)
				_add_label("گزارش آخر:\\n"+str(s.last_report), 16)
			_add_button("💾 ذخیره شهر", self, "save_now")
		"buildings":
			_add_label("ساخت‌وساز شهر", 22)
			_add_label("زمین شهر: %d قطعه | اشغال‌شده: %d | آزاد: %d" % [int(s.get("land_owned",10)),game.get_land_used(),game.get_land_free()], 19)
			_add_label("برای گسترش شهر باید زمین بخری؛ هر ساختمان چند قطعه از زمین را اشغال می‌کند.", 15)
			var land_button = _add_button("خرید ۱ قطعه زمین | قیمت: %d سکه" % game.get_land_unit_price(), self, "buy_land")
			land_button.disabled = game.get_available_money() < game.get_land_unit_price()
			var categories = ["همه","خانه‌ها","کشاورزی","معادن","کارخانه‌ها","کسب‌وکارها","خدمات شهری","تفریح و فرهنگ","انبارها","زیرساخت"]
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
			_add_label("ساختمان‌های فعلی:", 18)
			for i in range(s.buildings.size()):
				var id = s.buildings[i].id
				var building_location = str(s.buildings[i].get("district_name", "منطقه صنعتی خارج شهر"))
				_add_label("%s — محل: %s" % [str(game.get_building_definitions()[id].name), building_location], 15)
				if int(s.buildings[i].get("balance",0)) > 0:
					_add_label("حساب %s: %d سکه" % [str(game.get_building_definitions()[id].name),int(s.buildings[i].get("balance",0))])
					_add_button(" برداشت سود %s: %d سکه" % [str(game.get_building_definitions()[id].name),int(s.buildings[i].get("balance",0))], self, "collect_profit", [i])
				# Demolition is managed from the categorized city overview.
		"citizens":
			_add_label(" جمعیت: %d | شاغل: %d | بیکار: %d" % [s.population,game.get_employed_count(),game.get_unemployed_count()], 20)
			_add_label("ظرفیت مسکن: %d | ظرفیت شغلی: %d" % [game.get_housing_capacity(),game.get_job_capacity()])
			_add_label("رضایت شهروندان: %d/۱۰۰" % int(s.get("satisfaction",50)))
			_add_label("نیازهای روزانه: " + _needs_summary(), 15)
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
			for citizen in s.citizens:
				var citizen_role = "بیکار"
				if str(citizen.get("job","")) != "":
					citizen_role = "کارمند شهرداری: " + str(citizen.job)
				elif int(citizen.get("private_business_id",0)) > 0:
					citizen_role = "کارآفرین بخش خصوصی"
				elif int(citizen.get("private_job_id",0)) > 0:
					citizen_role = "کارمند بخش خصوصی"
				_add_label("شهروند %s — %s | کیف پول: %d سکه | زمین خصوصی: %d قطعه" % [str(citizen.id),citizen_role,int(citizen.get("wallet",0)),int(citizen.get("private_land",0))])
				var interest_names = {"food":"خوراک","industry":"صنعت","services":"خدمات"}
				_add_label("استعداد کارآفرینی: %d | ریسک‌پذیری: %d | علاقه: %s | پس‌انداز: %d" % [int(citizen.get("entrepreneurship",0)),int(citizen.get("risk_tolerance",0)),str(interest_names.get(str(citizen.get("business_interest","")),"نامشخص")),int(citizen.get("saving_habit",0))], 14)
			_add_button(" تخصیص دوباره شغل‌ها", self, "reassign_jobs")
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
			_add_label("🏪 اقتصاد مستقل شهروندان", 22)
			_add_label("کسب‌وکار خصوصی: %d | فروش روزانه: %d سکه" % [int(private_economy_data.get("business_count",0)),int(private_economy_data.get("daily_revenue",0))], 18)
			_add_label("سرمایه در گردش بخش خصوصی: %d سکه" % int(private_economy_data.get("private_balance",0)), 17)
			_add_label("مالیات پرداختی امروز: %d سکه | نرخ مالیات: %d٪" % [int(private_economy_data.get("daily_tax",0)),int(private_economy_data.get("tax_rate",8))], 17)
			if private_economy_data.get("private_businesses", []).empty():
				_add_label("هنوز کسب‌وکار خصوصی تأسیس نشده است. شهروندان پس از جمع‌آوری سرمایه، برای خرید زمین و دریافت مجوز درخواست می‌دهند.", 16)
			for business in private_economy_data.get("private_businesses", []):
				_add_label("%s | مالک: شهروند %d | کارمند: %d | فروش روزانه: %d سکه" % [str(business.get("name","کسب‌وکار")),int(business.get("owner_citizen_id",0)),business.get("employees",[]).size(),int(business.get("last_revenue",0))], 17)
				_add_label("سرمایه کسب‌وکار: %d | مالیات امروز: %d | اعتبار مالیاتی پروژه‌ها: %d" % [int(business.get("balance",0)),int(business.get("last_tax",0)),int(business.get("tax_credit",0))], 15)
				if bool(business.get("rented_municipal",false)):
					_add_label("ملک متعلق به شهرداری است؛ پایان قرارداد اجاره: روز %d" % int(business.get("rent_until_day",0)), 14)
			_add_label("شهروندان بیکار درآمد آزاد کسب می‌کنند؛ کسب‌وکارها به‌تدریج نیروی کار استخدام می‌کنند و از فروش خود مالیات می‌پردازند.", 15)
		"commerce":
			_add_label("🛒 بازار، تجارت و واردات", 22)
			_add_label("خریدوفروش داخل شهر، صادرات به شهرهای دیگر و واردات کالا از شهرهای همسایه در یک بخش.", 15)
			_add_label("بازار داخلی — قیمت‌ها بر اساس عرضه و تقاضا", 20)
			_add_label("موجودی بازار کمتر باشد، قیمت بالاتر می‌رود؛ با افزایش موجودی، قیمت کاهش می‌یابد.", 15)
			for id in game.get_resource_definitions().keys():
				var d = game.get_resource_definitions()[id]
				var stock = int(s.resources.get(id,0))
				var market_stock = int(s.market_stock.get(id,0))
				var buy_price = game.get_market_price(id,"buy")
				var sell_price = game.get_market_price(id,"sell")
				_add_label("%s | انبار: %d | موجودی بازار: %d/۱۰۰ | خرید: %d | فروش: %d" % [d.name,stock,market_stock,buy_price,sell_price])
				var buy_button = _add_button("خرید ۵ واحد "+d.name, self, "buy_item", [id,5])
				buy_button.disabled = int(s.market_stock.get(id,0)) < 5 or game.get_free_storage() < 5 or game.get_available_money() < buy_price * 5
				var sell_button = _add_button("فروش ۵ واحد "+d.name, self, "sell_item", [id,5])
				sell_button.disabled = stock < 5 or int(s.market_stock.get(id,0)) > 95 or game.get_available_money() >= game.get_treasury_capacity()
			_add_label("🌐 صادرات و تجارت با شهرهای دیگر", 20)
			_add_label("هر شهر تقاضا و ظرفیت خرید روزانه دارد. صادرات با قیمت توافقی انجام می‌شود و درآمد مستقیم به خزانه می‌رود.", 15)
			_add_label("ظرفیت باقی‌مانده امروز:", 18)
			for city_id in game.get_trade_cities().keys():
				var city = game.get_trade_cities()[city_id]
				_add_label("%s: %d / %d واحد" % [city.name,int(s.trade_remaining.get(city_id,city.daily_capacity)),int(city.daily_capacity)])
				for resource_id in game.get_resource_definitions().keys():
					var export_price = game.get_trade_export_price(city_id,resource_id)
					if export_price <= 0:
						continue
					var city_demand_left = int(s.trade_demand_remaining.get(city_id,city.demand).get(resource_id,0))
					_add_label("%s — %s | تقاضای باقی‌مانده: %d | قیمت صادرات: %d سکه" % [city.name,game.get_resource_definitions()[resource_id].name,city_demand_left,export_price],15)
					var export_button = _add_button("صادرات ۵ واحد "+game.get_resource_definitions()[resource_id].name+" به "+city.name,self,"export_to_city",[city_id,resource_id,5])
					export_button.disabled = int(s.resources.get(resource_id,0)) <= 0 or int(s.trade_remaining.get(city_id,city.daily_capacity)) <= 0 or game.get_transport_capacity_remaining() <= 0
			_add_label("آخرین معامله: "+str(s.get("last_trade_report","هنوز معامله‌ای انجام نشده است.")),16)
			_add_label("📦 واردات از شهرهای دیگر", 20)
			_add_label("ظرفیت کامیون آزاد امروز: %d از %d واحد" % [game.get_transport_capacity_remaining(),game.get_transport_daily_capacity()],16)
			_add_label("هزینه کالا و ۱۰٪ کرایه حمل هنگام سفارش پرداخت می‌شود. محموله پس از ۱ یا ۲ روز می‌رسد.",15)
			for city_id in game.get_import_cities().keys():
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
			_add_label("محموله‌های در راه:",18)
			if s.trade_shipments.empty():
				_add_label("محموله‌ای در راه نیست.")
			for shipment in s.trade_shipments:
				var shipment_city = game.get_import_cities().get(str(shipment.get("city_id","")) ,{"name":"نامشخص"})
				var shipment_resource = game.get_resource_definitions().get(str(shipment.get("resource_id","")) ,{"name":"کالای نامشخص"})
				_add_label("#%d | %s | %d واحد %s | تحویل روز %d" % [int(shipment.get("id",0)),shipment_city.name,int(shipment.get("amount",0)),shipment_resource.name,int(shipment.get("arrival_day",0))],15)
			_add_label("آخرین سفارش: "+str(s.get("last_import_report","")),15)
			_add_label("قراردادهای واردات:",18)
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
			for import_city_id in game.get_import_cities().keys():
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
				facility_button.disabled = int(s.population) < int(facility.get("unlock",0)) or int(s.level) < int(facility.get("level_unlock",1)) or game.get_available_money() < int(facility.get("cost",0)) or game.get_land_free() < game.get_land_size(facility_id)
			_add_label("🚚 پایانه و ناوگان کامیون",19)
			_add_label("پایانه حمل‌ونقل: %d | کامیون فعال: %d | ظرفیت روزانه: %d واحد" % [game.get_building_count("transport_depot"),game.get_transport_truck_count(),game.get_transport_daily_capacity()],17)
			_add_label("ظرفیت مصرف‌شده امروز: %d | ظرفیت باقی‌مانده: %d" % [int(s.get("transport_used_today",0)),game.get_transport_capacity_remaining()],16)
			_add_label("هر پایانه با ۲ کارمند، یک کامیون را فعال می‌کند؛ هر پایانه حداکثر ۲ کامیون پشتیبانی می‌کند.",15)
			_add_label("نگهداری روزانه ناوگان: %d سکه | نگهداری جاده: %d سکه" % [game.get_fleet_maintenance(),game.get_road_maintenance()],16)
			var depot = game.get_building_definitions().get("transport_depot",{})
			if not depot.empty():
				var depot_button = _add_button("ساخت پایانه حمل‌ونقل — %d سکه | زمین: %d قطعه" % [int(depot.get("cost",0)),game.get_land_size("transport_depot")],self,"build_transport_facility",["transport_depot"])
				depot_button.disabled = int(s.population) < int(depot.get("unlock",0)) or int(s.level) < int(depot.get("level_unlock",1)) or game.get_available_money() < int(depot.get("cost",0)) or game.get_land_free() < game.get_land_size("transport_depot")
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
			_add_label(" مدیریت انبار", 22)
			_add_label("ظرفیت: %d | مصرف‌شده: %d | فضای خالی: %d" % [game.get_storage_capacity(),game.get_storage_used(),game.get_free_storage()])
			_add_label(" ذخیره درختان جنگل: %d / ۱۰۰" % game.get_forest_tree_count())
			for id in game.get_resource_definitions().keys():
				_add_label("%s: %d" % [game.get_resource_definitions()[id].name,s.resources.get(id,0)])
		"report":
			_add_label(" گزارش روزانه", 22)
			var report_economy = s.get("last_economy", {})
			_add_label("درآمد مالیات: %d سکه" % int(report_economy.get("tax_income",0)))
			_add_label("خرید شهروندان: %d سکه از %d خریدار" % [int(report_economy.get("consumer_spending",0)),int(report_economy.get("consumer_buyers",0))])
			_add_label("غذای مصرف‌شده شهروندان: %d واحد | ذخیره پایان روز: %d" % [int(report_economy.get("food_units_consumed",0)),int(report_economy.get("food_stock",0))])
			_add_label("واریزی حساب فروشگاه‌ها: %d سکه" % int(report_economy.get("consumer_business_revenue",0)))
			_add_label("مالیات خرید شهروندان: %d سکه" % int(report_economy.get("consumer_tax_income",0)))
			_add_label("درآمد کسب‌وکارها: %d سکه" % int(report_economy.get("business_income",0)))
			_add_label("درآمد فروش منابع: %d سکه" % int(report_economy.get("resource_income",0)))
			_add_label("کل درآمد دریافت‌شده: %d سکه" % int(report_economy.get("accepted_income",0)))
			_add_label("حقوق پرداختی: %d از %d سکه" % [int(report_economy.get("wages_paid",0)),int(report_economy.get("wages_due",0))])
			_add_label("نگهداری ناوگان و جاده: %d سکه" % int(report_economy.get("maintenance_paid",0)))
			_add_label("تغییر خالص خزانه: %d سکه" % int(report_economy.get("net_cashflow",0)), 20)
			_add_label(str(s.last_report), 18)
			_add_button("رفتن به روز بعد", self, "advance_day")
		"missions":
			_add_label(" ماموریت‌های شهر", 22)
			_add_label("با تکمیل ماموریت‌ها پاداش سکه دریافت کن.")
			for mission_index in range(game.get_missions().size()):
				var mission = game.get_missions()[mission_index]
				var definition = {}
				for item in game.MISSION_DEFINITIONS:
					if str(item.id) == str(mission.get("id","")):
						definition = item
						break
				if definition.empty():
					continue
				var status = ("دریافت شده" if bool(mission.get("claimed",false)) else ("آماده دریافت" if bool(mission.get("completed",false)) else "در حال انجام"))
				_add_label("%s — %s" % [definition.title,status],18)
				_add_label("%s | پیشرفت: %d/%d | جایزه: %d سکه" % [definition.description,int(mission.get("progress",0)),int(definition.goal),int(definition.reward)],15)
				if bool(mission.get("completed",false)) and not bool(mission.get("claimed",false)):
					_add_button(" دریافت پاداش: "+str(definition.reward), self, "claim_mission", [mission_index])
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

func toggle_municipality_section(section_id):
	var key = str(section_id)
	municipality_section_expanded[key] = not bool(municipality_section_expanded.get(key, false))
	show_page("municipality")

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

func _add_building_category_items(category):
	var visible_buildings = 0
	for id in game.get_building_definitions().keys():
		var data = game.get_building_definitions()[id]
		if category != "همه" and str(data.get("category","")) != category:
			continue
		visible_buildings += 1
		var s = game.state
		var population_unlocked = s.population >= int(data.unlock)
		var required_level = int(data.get("level_unlock", 1))
		var level_unlocked = int(s.level) >= required_level
		var unlocked = population_unlocked and level_unlocked
		var label = "%s | هزینه: %d | زمین: %d قطعه | جمعیت: %d | سطح: %d" % [data.name,data.cost,game.get_land_size(id),data.unlock,required_level]
		if not population_unlocked or not level_unlocked:
			label += " | 🔒 قفل"
		var building_button = _add_button(label, self, "build_building", [id])
		building_button.disabled = not unlocked or game.get_available_money() < int(data.cost) or game.get_land_free() < game.get_land_size(id) or (id == "central_bank" and int(s.get("central_bank_rebuild_days_left",0)) > 0)
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

func claim_mission(index):
	var result = game.claim_mission(index)
	show_page("missions")
	_show_message(result.message)

func save_now():
	var ok = game.save_game()
	_show_message("شهر ذخیره شد." if ok else "ذخیره‌سازی ناموفق بود.")
