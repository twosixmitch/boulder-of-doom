class_name Game extends Node


func _enter_tree():
	Events.hit_hazard.connect(on_hit_hazard)


func _exit_tree():
	Events.hit_hazard.disconnect(on_hit_hazard)


func on_hit_hazard():
	Events.exit_game.emit()
