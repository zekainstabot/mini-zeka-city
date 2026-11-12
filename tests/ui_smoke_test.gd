extends SceneTree

const MainScene = preload("res://Main.tscn")
const EngineScript = preload("res://scripts/GameEngine.gd")

func _init():
	var main = MainScene.instance()
	get_root().add_child(main)
	main.game = EngineScript.new()
	main.game.new_game()
	for page in ["home","buildings","citizens","bank","municipality","private_economy","commerce","transport","imports","storage","report","missions"]:
		main.show_page(page)
	main.game.state["pending_offline_days"] = 2
	main.game.state["pending_offline_income"] = 350
	main._show_offline_summary()
	assert(main.offline_summary_popup != null)
	var offline_layout = main.offline_summary_popup.get_child(0).get_child(0)
	assert(offline_layout.get_child_count() == 5)
	assert(offline_layout.get_child(0) is Label)
	assert(offline_layout.get_child(1) is Label)
	assert(offline_layout.get_child(2) is Label)
	assert(offline_layout.get_child(3) is Button)
	assert(offline_layout.get_child(4) is Button)
	print("Mini ZekaCity UI smoke tests passed.")
	quit()
