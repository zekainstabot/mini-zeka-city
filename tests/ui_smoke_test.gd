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
	print("Mini ZekaCity UI smoke tests passed.")
	quit()
