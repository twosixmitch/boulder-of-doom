class_name HazardArea3D extends Area3D

var _activated: bool = false


func _on_body_entered(body):
	if _can_activate_from_body(body):
		activate()


func _on_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	if _can_activate_from_body(body):
		activate()


func _can_activate_from_body(body) -> bool:
	if _activated:
		return false
	
	if not body.is_in_group("player"):
		return false
	
	return true


func activate():
	_activated = true
	Events.hit_hazard.emit(global_position)
