class_name PropRigidBody extends RigidBody3D

## Layer 9 "Inactive Props" — prop is on this layer so Player / active Props ignore it.
const COLLISION_LAYER_INACTIVE_PROPS := 1 << (9 - 1)
## Collide only with layer 2 "World".
const COLLISION_MASK_WORLD_ONLY := 1 << (2 - 1)

@export var prop_type: Enums.PropType
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


func _physics_process(_delta):
	if linear_velocity.length_squared() > 2 and not _activated:
		activate_no_body()


func _on_spawn_grace_ended() -> void:
	_ready_to_activate = true


func _on_body_entered(body):
	if _can_activate_from_body(body):
		activate(body)


func _on_body_exited(_body) -> void:
	pass


func _on_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	if _can_activate_from_body(body):
		activate(body)


func _on_body_shape_exited(_body_rid, _body, _body_shape_index, _local_shape_index) -> void:
	pass


func _can_activate_from_body(body) -> bool:
	if _activated:
		return false

	if not _ready_to_activate:
		return false

	if not body.is_in_group("player") and not body.is_in_group("props"):
		return false

	return true


func activate(body):
	if not is_inside_tree():
		return

	_activated = true
	gravity_scale = 1.0
	call_deferred("set_contact_monitor", false)

	var direction = body.global_position - global_position
	direction.y = 0
	direction = -direction.normalized()
	direction.y = 1.2
	apply_impulse(direction * 0.8)

	Events.hit_prop.emit(prop_type, global_position)

	get_tree().create_timer(GameConfig.prop_collision_delay_sec).timeout.connect(
		_on_inactive_prop_collision_timer
	)


func activate_no_body():
	if not is_inside_tree():
		return

	_activated = true
	gravity_scale = 1.0
	call_deferred("set_contact_monitor", false)

	apply_impulse(Vector3.UP * 1.0)

	Events.hit_prop.emit(prop_type, global_position)

	get_tree().create_timer(GameConfig.prop_collision_delay_sec).timeout.connect(
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
	tween.tween_property(visuals, "scale", Vector3.ZERO, GameConfig.prop_vanish_duration).set_ease(
		Tween.EASE_IN
	).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(queue_free)
