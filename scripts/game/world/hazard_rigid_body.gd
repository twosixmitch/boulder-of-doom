class_name HazardRigidBody extends RigidBody3D

var _activated: bool = false


func _ready() -> void:
	sleeping = true
	gravity_scale = 0


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
	gravity_scale = 1
	Events.hit_hazard.emit()
