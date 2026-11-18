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
	assert(navigation_grid.columns == 2, "Narrow portrait navigation must stay in two columns")
	print("UI GEOMETRY clock=", main.day_night_hud.get_global_rect(), " menu=", main.menu_button.get_global_rect(), " calendar=", main.daily_reward_button.get_global_rect())
	assert(not main.daily_reward_button.get_global_rect().intersects(main.day_night_hud.get_global_rect()), "Calendar overlaps the clock on a narrow phone")
	assert(not main.menu_button.get_global_rect().intersects(main.day_night_hud.get_global_rect()), "Menu overlaps the clock on a narrow phone")
	assert(not main.help_button.get_global_rect().intersects(main.day_night_hud.get_global_rect()), "Help overlaps the clock on a narrow phone")
	assert(not main.daily_reward_button.get_global_rect().intersects(main.menu_button.get_global_rect()), "Calendar overlaps the menu shortcut")
	assert(not main.menu_button.get_global_rect().intersects(main.help_button.get_global_rect()), "Menu overlaps the help shortcut")
	var top_shortcuts = [main.daily_reward_button, main.menu_button, main.help_button, main.ranking_button, main.report_button]
	print("UI GEOMETRY clock=", main.day_night_hud.get_global_rect(), " calendar=", main.daily_reward_button.get_global_rect(), " menu=", main.menu_button.get_global_rect(), " help=", main.help_button.get_global_rect(), " rank=", main.ranking_button.get_global_rect(), " report=", main.report_button.get_global_rect())
	for i in range(top_shortcuts.size()):
		for j in range(i + 1, top_shortcuts.size()):
			assert(not top_shortcuts[i].get_global_rect().intersects(top_shortcuts[j].get_global_rect()), "Top shortcuts overlap on a narrow phone")
		assert(not top_shortcuts[i].get_global_rect().intersects(main.day_night_hud.get_global_rect()), "A top shortcut overlaps the clock on a narrow phone")
	assert(not main.construction_capacity_button.get_global_rect().intersects(main.day_night_hud.get_global_rect()), "Construction shortcut overlaps the clock")
	assert(not main.construction_capacity_button.get_global_rect().intersects(main.report_button.get_global_rect()), "Construction shortcut overlaps the report shortcut")
	main.report_button.emit_signal("pressed")
	assert(main.current_page == "report", "Top report shortcut does not open reports")
	main.ranking_button.emit_signal("pressed")
	assert(main.current_page == "ranking", "Top ranking shortcut does not open rankings")
	main.show_page("home")
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
	# Settings menu must fully cover the city and keep restart confirmation inside the modal.
	assert(is_equal_approx(main.menu_overlay.color.a, 1.0), "Settings menu backdrop must be opaque")
	main._toggle_game_menu()
	assert(main.menu_overlay.visible and main.menu_panel.visible, "Settings menu did not open")
	var menu_close = main.menu_overlay.find_child("MenuCloseButton", true, false)
	assert(menu_close is Button and menu_close.text == "✕", "Settings menu header X button is missing")
	assert(main.menu_panel.find_child("MenuAction__close_game_menu", true, false) == null, "Redundant bottom close-menu action still exists")
	var restart_action = main.menu_panel.find_child("MenuAction_confirm_restart_from_menu", true, false)
	assert(restart_action is Button, "Restart city action is missing")
	assert(main.menu_panel.get_child(main.restart_confirm_panel.get_index() - 1) == restart_action, "Restart confirmation is not directly below its action")
	restart_action.emit_signal("pressed")
	await process_frame
	assert(main.menu_overlay.visible, "Restart confirmation unexpectedly closed the settings menu")
	assert(main.restart_confirm_panel.visible, "Restart confirmation did not appear")
	main._cancel_restart()
	assert(not main.restart_confirm_panel.visible, "Cancel did not hide restart confirmation")
	var help_action = main.menu_panel.find_child("MenuAction_open_help", true, false)
	assert(help_action is Button, "Help action is missing from settings menu")
	help_action.emit_signal("pressed")
	await process_frame
	assert(main.help_overlay.visible, "Help action did not open the help overlay")
	assert(not main.menu_overlay.visible, "Settings menu remained visible behind help")
	main._close_help()
	await process_frame
	assert(not main.help_overlay.visible, "Closing help did not hide its overlay")
	assert(main._get_geographic_rank_name(1) == "آبادی کوچک")
	assert(main._get_geographic_rank_name(3) == "آبادی کوچک")
	assert(main._get_geographic_rank_name(4) == "آبادی")
	assert(main._get_geographic_rank_name(6) == "آبادی")
	assert(main._get_geographic_rank_name(7) == "آبادی بزرگ")
	assert(main._get_geographic_rank_name(9) == "آبادی بزرگ")
	assert(main._get_geographic_rank_name(10) == "روستای کوچک")
	for page in ["home","map","buildings","citizens","bank","municipality","private_economy","commerce","transport","imports","storage","report","missions","progress","ranking","settings","audio","help"]:
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
	main.show_page("map")
	# Search from the scene root so nested page layout wrappers are included.
	var map_canvas = main.find_child("CityMapCanvas", true, false)
	assert(map_canvas is PanelContainer, "City map canvas is missing from the active scene")
	var map_overview = main.game.get_districts_overview()
	var map_districts = map_overview.get("districts", [])
	if not map_districts.is_empty():
		var first_district_id = str(map_districts[0].get("id", ""))
		assert(map_canvas.find_child("DistrictTile_" + first_district_id, true, false) is PanelContainer, "Generated district tile is missing from the city map")
		main.select_map_district(first_district_id)
		assert(main.content.find_child("SelectedDistrictDetails", true, false) is PanelContainer, "Selecting a map district must show its details")
		var building_dot = map_canvas.find_child("BuildingDot_building_0", true, false)
		assert(building_dot is Button, "Individual building point is missing from the city map")
		building_dot.emit_signal("pressed")
		assert(main.content.find_child("SelectedMapBuildingDetails", true, false) is PanelContainer, "Tapping a building point must show its details")
		assert(main.selected_map_building_data.get("building_id", "") == "small_house", "Building point selected the wrong building")
	main.show_page("home")
	main.home_city_details_expanded = true
	main.show_page("home")
	assert(main.content.get_child_count() > 0)
	var overview_panel = main.content.find_child("HomeOverviewPanel", true, false)
	assert(overview_panel is PanelContainer, "Home page city overview panel is missing")
	var overview_grid = overview_panel.find_child("CityOverviewGrid", true, false)
	assert(overview_grid is GridContainer and overview_grid.get_child_count() == 6, "Home overview must show all six city metrics")
	main.game.state["constructions"] = [{"id":"small_house","finish_at":int(Time.get_unix_time_from_system()) + 125,"district_name":"محله آزمایشی"}]
	main.show_page("home")
	var construction_panel = main.content.find_child("HomeConstructionPanel", true, false)
	assert(construction_panel is PanelContainer, "Active construction is not visible on the home page")
	assert(construction_panel.get_child_count() > 0)
	main.game.state["constructions"] = []
	main.show_page("home")
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
