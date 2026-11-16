extends SceneTree

const MainScene = preload("res://Main.tscn")
const EngineScript = preload("res://scripts/GameEngine.gd")

func _initialize():
	# SceneTree._init runs before the root viewport is ready. Defer UI setup
	# until the tree is initialized so layout and viewport APIs are valid.
	call_deferred("_run_tests")

func _run_tests():
	# Make the headless test viewport deterministic and match a portrait phone.
	get_root().size = Vector2i(720, 1280)
	await process_frame
	var main = MainScene.instantiate()
	get_root().add_child(main)
	await process_frame
	assert(main.startup_loading_layer != null and is_instance_valid(main.startup_loading_layer), "Full-screen loading screen was not shown on launch")
	print("UI TEST: waiting for automatic startup loading")
	# Main._ready() intentionally awaits several loading milestones before it
	# builds the playable UI. Wait for the real UI instead of assuming one frame.
	var startup_wait_frames = 0
	while main.header_label == null and startup_wait_frames < 240:
		await process_frame
		startup_wait_frames += 1
	assert(main.header_label != null, "Main UI did not finish startup within 240 frames")
	print("UI TEST: startup UI ready after %d frames" % startup_wait_frames)
	if main.city_name_input != null and is_instance_valid(main.city_name_input):
		main._choose_random_city_name()
		assert(not main.city_name_input.text.strip_edges().is_empty())
		assert(main.city_name_overlay != null and is_instance_valid(main.city_name_overlay))
	var text_server = TextServerManager.get_primary_interface()
	assert(text_server != null)
	assert(text_server.has_feature(TextServer.FEATURE_SHAPING))
	# Bidi capability can be unavailable in headless CI builds; verify the
	# actual UI direction below instead of treating this optional feature as a blocker.
	assert(main.is_layout_rtl())
	assert(main.header_label.is_layout_rtl())
	assert(main.header_label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART)
	await process_frame
	var main_layout = main.get_node("MainLayout")
	var navigation_grid = main_layout.get_node("MainNavigationGrid")
	assert(navigation_grid.get_combined_minimum_size().x <= main_layout.size.x + 1.0)
	assert(main.ui_font is Font)
	main.game = EngineScript.new()
	main.game.new_game()
	# Exercise responsive layouts at narrow-phone, reference portrait, and landscape sizes.
	get_root().size = Vector2i(360, 800)
	await process_frame
	main._apply_responsive_layout()
	await process_frame
	print("UI TEST: narrow viewport=", main.get_viewport_rect().size, " calendar=", main.daily_reward_button.get_global_rect(), " clock=", main.day_night_hud.get_global_rect(), " safe=", main.safe_area_insets)
	assert(navigation_grid.columns == 2, "Narrow portrait navigation must stay in two columns")
	assert(not main.daily_reward_button.get_global_rect().intersects(main.day_night_hud.get_global_rect()), "Calendar overlaps the clock on a narrow phone")
	assert(not main.menu_button.get_global_rect().intersects(main.day_night_hud.get_global_rect()), "Menu overlaps the clock on a narrow phone")
	assert(not main.help_button.get_global_rect().intersects(main.day_night_hud.get_global_rect()), "Help overlaps the clock on a narrow phone")
	assert(not main.daily_reward_button.get_global_rect().intersects(main.menu_button.get_global_rect()), "Calendar overlaps the menu shortcut")
	assert(not main.menu_button.get_global_rect().intersects(main.help_button.get_global_rect()), "Menu overlaps the help shortcut")
	assert(not main.construction_capacity_button.get_global_rect().intersects(main.day_night_hud.get_global_rect()), "Construction shortcut overlaps the clock")
	assert(navigation_grid.get_combined_minimum_size().x <= main_layout.size.x + 1.0, "Narrow navigation exceeds the safe content width")
	for nav_button in main.navigation_buttons:
		assert(nav_button.alignment == HORIZONTAL_ALIGNMENT_CENTER, "Navigation button text is not centered")
		assert(nav_button.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "Navigation button text does not wrap")
	main._open_daily_reward_calendar()
	await process_frame
	var reward_center = main.daily_reward_layer.get_child(0).get_child(0)
	var reward_card = reward_center.get_child(0)
	var reward_layout = reward_card.get_child(0)
	var reward_scroll = reward_layout.get_child(4)
	var reward_grid = reward_scroll.get_child(0)
	assert(reward_grid.columns == 2, "Daily reward tiles must use two columns on a narrow phone")
	assert(reward_card.get_global_rect().position.x >= reward_center.get_global_rect().position.x - 1.0, "Daily reward card exceeds left safe bound")
	assert(reward_card.get_global_rect().end.x <= reward_center.get_global_rect().end.x + 1.0, "Daily reward card exceeds right safe bound")
	main._close_daily_reward_calendar()
	get_root().size = Vector2i(1280, 720)
	await process_frame
	main._apply_responsive_layout()
	await process_frame
	assert(navigation_grid.columns == 3, "Landscape navigation must use three columns")
	assert(not main.help_button.get_global_rect().intersects(main.day_night_hud.get_global_rect()), "Help overlaps the clock in landscape")
	get_root().size = Vector2i(720, 1280)
	await process_frame
	main._apply_responsive_layout()
	await process_frame
	assert(main._get_geographic_rank_name(1) == "آبادی کوچک")
	assert(main._get_geographic_rank_name(3) == "آبادی کوچک")
	assert(main._get_geographic_rank_name(4) == "آبادی")
	assert(main._get_geographic_rank_name(6) == "آبادی")
	assert(main._get_geographic_rank_name(7) == "آبادی بزرگ")
	assert(main._get_geographic_rank_name(9) == "آبادی بزرگ")
	assert(main._get_geographic_rank_name(10) == "روستای کوچک")
	for page in ["home","buildings","citizens","bank","municipality","private_economy","commerce","transport","imports","storage","report","missions","progress","ranking","settings","audio","help"]:
		print("UI TEST: opening page %s" % page)
		main.show_page(page)
		if page == "ranking":
			assert(main.content.get_child_count() >= 12)
			assert(main.game.get_rival_standings().size() == 10)
		if page == "settings":
			assert(main.content.get_child_count() > 0)
		if page == "audio":
			assert(main.content.get_child_count() >= 18)
		if page == "help":
			assert(main.content.get_child_count() > 30)
		print("UI TEST: page %s ready (%d controls)" % [page, main.content.get_child_count()])
	main.home_city_details_expanded = true
	main.show_page("home")
	assert(main.content.get_child_count() > 0)
	var service_panel_found = false
	for child in main.content.get_children():
		if child is PanelContainer:
			service_panel_found = true
			break
	assert(service_panel_found)
	main.game.state["pending_offline_days"] = 2
	main.game.state["pending_offline_income"] = 350
	main.game.state["pending_offline_summary_ready"] = true
	print("UI TEST: opening offline summary")
	main._show_offline_summary()
	assert(main.offline_summary_popup is Control)
	assert(main.offline_summary_popup.name == "WelcomeBackOverlay")
	var offline_center = main.offline_summary_popup.get_child(1)
	assert(offline_center is CenterContainer)
	var offline_card = offline_center.get_child(0)
	assert(offline_card is PanelContainer)
	var offline_scroll = offline_card.get_child(0)
	assert(offline_scroll is ScrollContainer)
	var offline_layout = offline_scroll.get_child(0)
	assert(offline_layout is VBoxContainer)
	# Match the current welcome-back card: icon, heading, intro, stats,
	# news heading/panel, primary action, and reassurance text.
	assert(offline_layout.get_child_count() >= 8)
	assert(offline_layout.get_child(0) is CenterContainer)
	assert(offline_layout.get_child(1) is Label)
	assert(offline_layout.get_child(2) is Label)
	assert(offline_layout.get_child(3) is HBoxContainer)
	assert(offline_layout.get_child(4) is Label)
	assert(offline_layout.get_child(5) is PanelContainer)
	assert(offline_layout.get_child(6) is Button)
	assert(offline_layout.get_child(7) is Label)
	print("Mini ZekaCity UI smoke tests passed.")
	quit()
