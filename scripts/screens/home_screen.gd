class_name HomeScreen extends Node


func _on_play_button_pressed():
	Events.start_new_game.emit()
