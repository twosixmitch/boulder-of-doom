class_name PropRigidBody extends RigidBody3D

@export var prop_type: Enums.PropType

var _activated: bool = false
var _ready_to_activate: bool = false


func _ready() -> void:
	sleeping = true
	gravity_scale = 0
	get_tree().create_timer(1.0).timeout.connect(_on_spawn_grace_ended)


func _process(_delta):
	if _activated and gravity_scale != 1:
		gravity_scale = 1


func _on_spawn_grace_ended() -> void:
	_ready_to_activate = true


func _on_body_entered(body):
	if _can_activate_from_body(body):
		activate(body)


func _on_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	if _can_activate_from_body(body):
		activate(body)
	

func _can_activate_from_body(body) -> bool:
	if _activated:
		return false

	if not _ready_to_activate:
		return false
	
	if not body.is_in_group("player") and not body.is_in_group("props"):
		return false
	
	return true


func activate(body):
	print("activate: %s" % self.name)
	_activated = true
	gravity_scale = 1.0
	call_deferred("set_contact_monitor", false)

	# Pop the prop up in the air on an angle away from the body that hit it using physics.
	# The angle should still send it upwards, but also away from the body.
	var direction = body.global_position - global_position
	direction.y = 0
	direction = -direction.normalized()
	direction.y = 1.0
	apply_impulse(direction * 0.80)
	
	GameManager.prop_hit(prop_type, global_position)
