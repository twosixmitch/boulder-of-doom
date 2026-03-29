class_name MainMenuUI extends Node


func _on_play_button_pressed():
	Events.start_new_game.emit()
