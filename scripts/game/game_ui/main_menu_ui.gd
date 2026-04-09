class_name MainMenuUI extends Node


func _on_play_button_pressed():
	Events.start_new_game.emit()


func _on_play_button_1_pressed():
	Events.start_new_game_scene.emit(1)


func _on_play_button_2_pressed():
	Events.start_new_game_scene.emit(2)


func _on_play_button_3_pressed():
	Events.start_new_game_scene.emit(3)


func _on_play_button_4_pressed():
	Events.start_new_game_scene.emit(4)


func _on_play_button_5_pressed():
	Events.start_new_game_scene.emit(5)
