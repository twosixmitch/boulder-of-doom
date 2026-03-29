extends Node

var score: int = 0


func prop_hit(_prop_type: Enums.PropType, world_position: Vector3) -> void:
	var point_value = 1
	score += point_value
	
	Events.score_changed.emit(score)
	Events.display_point.emit(point_value, world_position)
