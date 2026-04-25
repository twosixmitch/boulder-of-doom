extends Node

@export var content_parent: Node

func _ready():
	Events.start_new_game.connect(on_start_new_game)
	Events.start_new_game_scene.connect(on_start_new_game_scene)
	Events.exit_game.connect(on_exit_game)
	
	GameStateService.load_data()
	WalletService.load_data()
	
	go_to_home_screen()


func go_to_home_screen():
	change_screen("res://scenes/home_screen.tscn")


func on_start_new_game():
	change_screen("res://scenes/game.tscn")


func on_start_new_game_scene(scene_num: int):
	change_screen("res://scenes/game_%s.tscn" % scene_num)


func on_exit_game():
	go_to_home_screen()


func change_screen(path: String):
	var packed = ResourceLoader.load(path)
	if not packed:
		printerr("Failed to load screen: %s" % path)
		return
	var screen_node = packed.instantiate() as ScreenNode

	for child in content_parent.get_children():
		child.queue_free()
	
	content_parent.add_child(screen_node)
	
	# Allow the system to resize content so calling `.size` returns valid data.
	await get_tree().process_frame
	
	screen_node.on_screen_enter()
