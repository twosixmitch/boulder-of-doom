extends Node

@export var content_parent: Node

func _ready():
	Events.start_new_game.connect(on_start_new_game)
	Events.start_new_game_scene.connect(on_start_new_game_scene)
	Events.exit_game.connect(on_exit_game)
	
	go_to_main_menu()


func go_to_main_menu():
	change_screen("res://scenes/main_menu.tscn")


func on_start_new_game():
	change_screen("res://scenes/game_1.tscn")
	
func on_start_new_game_scene(scene_num: int):
	change_screen("res://scenes/game_%s.tscn" % scene_num)


func on_exit_game():
	go_to_main_menu()


func change_screen(path: String):
	var node = ResourceLoader.load(path).instantiate()

	for child in content_parent.get_children():
		child.queue_free()
	
	content_parent.add_child(node)
