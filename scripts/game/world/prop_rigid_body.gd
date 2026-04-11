class_name PropRigidBody extends RigidBody3D

## Seconds after activation before the prop moves to Inactive Props layer (see project 3D physics layers).
const COLLISION_WORLD_ONLY_DELAY_SEC := 1.0
## Layer 9 "Inactive Props" — prop is on this layer so Player / active Props ignore it.
const COLLISION_LAYER_INACTIVE_PROPS := 1 << (9 - 1)
## Collide only with layer 2 "World".
const COLLISION_MASK_WORLD_ONLY := 1 << (2 - 1)

@export var prop_type: Enums.PropType
@export var vanish_duration: float = 0.5
## Child Node3D that holds meshes (scaled to zero when the prop vanishes).
@export var visuals_path: NodePath = ^"Visuals"

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
	#print("activate: %s" % self.name)
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

	get_tree().create_timer(COLLISION_WORLD_ONLY_DELAY_SEC).timeout.connect(
		_on_inactive_prop_collision_timer
	)


func _on_inactive_prop_collision_timer() -> void:
	if not is_instance_valid(self) or not is_inside_tree():
		return
	collision_layer = COLLISION_LAYER_INACTIVE_PROPS
	collision_mask = COLLISION_MASK_WORLD_ONLY
	_start_visuals_vanish()


func _start_visuals_vanish() -> void:
	var visuals := get_node_or_null(visuals_path) as Node3D
	if visuals == null:
		push_warning("PropRigidBody '%s': no Node3D at visuals_path %s; freeing." % [name, visuals_path])
		queue_free()
		return

	var tween := create_tween()
	tween.tween_property(visuals, "scale", Vector3.ZERO, vanish_duration).set_ease(
		Tween.EASE_IN
	).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(queue_free)
