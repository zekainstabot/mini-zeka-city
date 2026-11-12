extends SceneTree

const MainScene = preload("res://Main.tscn")
const EngineScript = preload("res://scripts/GameEngine.gd")

func _initialize():
	# SceneTree._init runs before the root viewport is ready. Defer UI setup
	# until the tree is initialized so layout and viewport APIs are valid.
	call_deferred("_run_tests")

func _run_tests():
	var main = MainScene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.game = EngineScript.new()
	main.game.new_game()
	assert(main._get_geographic_rank_name(1) == "آبادی کوچک")
	assert(main._get_geographic_rank_name(3) == "آبادی کوچک")
	assert(main._get_geographic_rank_name(4) == "آبادی")
	assert(main._get_geographic_rank_name(6) == "آبادی")
	assert(main._get_geographic_rank_name(7) == "آبادی بزرگ")
	assert(main._get_geographic_rank_name(9) == "آبادی بزرگ")
	assert(main._get_geographic_rank_name(10) == "روستای کوچک")
	for page in ["home","buildings","citizens","bank","municipality","private_economy","commerce","transport","imports","storage","report","missions","progress","audio","help"]:
		main.show_page(page)
		if page == "audio":
			assert(main.content.get_child_count() >= 18)
		if page == "help":
			assert(main.content.get_child_count() > 30)
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
	main._show_offline_summary()
	assert(main.offline_summary_popup != null)
	var offline_layout = main.offline_summary_popup.get_child(0).get_child(0)
	assert(offline_layout.get_child_count() >= 8)
	assert(offline_layout.get_child(0) is Label)
	assert(offline_layout.get_child(1) is Label)
	assert(offline_layout.get_child(2) is HBoxContainer)
	assert(offline_layout.get_child(4) is ScrollContainer)
	assert(offline_layout.get_child(6) is Button)
	assert(offline_layout.get_child(7) is Button)
	print("Mini ZekaCity UI smoke tests passed.")
	quit()
