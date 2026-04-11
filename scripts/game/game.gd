class_name Game extends Node

@export var game_ui: GameUI
@export var player_controller: PlayerController

var current_score: int


func _enter_tree():
	Events.hit_prop.connect(on_hit_prop)
	Events.hit_hazard.connect(on_hit_hazard)


func _exit_tree():
	Events.hit_prop.disconnect(on_hit_prop)
	Events.hit_hazard.disconnect(on_hit_hazard)


func on_hit_hazard():
	player_controller.on_hit_hazard()
	print("on_hit_hazard")


func on_hit_prop(_prop_type: Enums.PropType, world_position: Vector3):
	var point_value = 1
	current_score += point_value
	
	game_ui.update_score(current_score)
	game_ui.display_point(point_value, world_position)
