extends Node

@export var content_parent: Node

func _ready():
	Events.start_new_game.connect(on_start_new_game)
	Events.exit_game.connect(on_exit_game)
	
	go_to_main_menu()


func go_to_main_menu():
	change_screen("res://scenes/main_menu.tscn")


func on_start_new_game():
	change_screen("res://scenes/game.tscn")


func on_exit_game():
	go_to_main_menu()


func change_screen(path: String):
	var node = ResourceLoader.load(path).instantiate()

	for child in content_parent.get_children():
		child.queue_free()
	
	content_parent.add_child(node)
