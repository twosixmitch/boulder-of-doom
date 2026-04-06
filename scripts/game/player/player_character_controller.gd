class_name PlayerCharacterController extends Node3D

# Nodes

@onready var sphere: RigidBody3D = $Sphere
@onready var raycast: RayCast3D = $Ground

@onready var visual_model = $Container


## Same steering / drive model as `ball_controller.gd`: continuous forward along
## `downhill_dir`, steer with ui_left / ui_right.

@export var steer_force: float = 600.0
@export var max_lateral_speed: float = 1.2
@export var lateral_friction: float = 6.0

@export var downhill_dir: Vector3 = Vector3(0, 0, 1)
@export var min_forward_speed: float = 10.0
@export var forward_drive_strength: float = 2.0
@export var max_forward_force: float = 100.0
@export var max_downhill_speed: float = 15.0

## Extra yaw around local **Y** after `look_at` (rarely needed; try ±TAU/4 if the rig faces sideways).
@export var visual_yaw_offset: float = 0.0

var normal: Vector3 = Vector3.UP

var linear_velocity: Vector3
var prev_position: Vector3


# Public Functions

func get_player_position() -> Vector3:
	if visual_model:
		return visual_model.global_position
	return Vector3.ZERO


func _physics_process(delta: float) -> void:
	var downhill := _downhill_direction()
	_apply_downhill_drive(downhill)
	_clamp_lateral_speed()
	_clamp_downhill_speed(downhill)
	_apply_lateral_control(delta)

	visual_model.position = sphere.position - Vector3(0, 0.65, 0)
	raycast.position = sphere.position

	#_orient_visual_to_run_direction(downhill)

	linear_velocity = (visual_model.position - prev_position) / delta
	prev_position = visual_model.position


func _downhill_direction() -> Vector3:
	if downhill_dir.length() > 0.001:
		return downhill_dir.normalized()
	return Vector3(0, 0, 1)


func _apply_downhill_drive(downhill: Vector3) -> void:
	if min_forward_speed <= 0.0:
		return

	var v_forward := sphere.linear_velocity.dot(downhill)
	if v_forward >= min_forward_speed:
		return

	var dv: float = min_forward_speed - v_forward
	var desired_force: float = dv * forward_drive_strength * sphere.mass
	var clamped_force: float = clampf(desired_force, 0.0, max_forward_force)

	if clamped_force > 0.0:
		sphere.apply_force(downhill * clamped_force)


func _clamp_lateral_speed() -> void:
	if abs(sphere.linear_velocity.x) <= max_lateral_speed:
		return

	var v := sphere.linear_velocity
	v.x = sign(v.x) * max_lateral_speed
	sphere.linear_velocity = v


func _clamp_downhill_speed(downhill: Vector3) -> void:
	if max_downhill_speed <= 0.0:
		return

	var v_forward := sphere.linear_velocity.dot(downhill)
	if v_forward <= max_downhill_speed:
		return

	sphere.linear_velocity += downhill * (max_downhill_speed - v_forward)


func _apply_lateral_control(delta: float) -> void:
	var steer_axis := -Input.get_axis("ui_left", "ui_right")

	if abs(steer_axis) > 0.001:
		sphere.apply_force(Vector3(steer_axis * steer_force, 0.0, 0.0))
	else:
		_damp_lateral_motion(delta)


func _damp_lateral_motion(delta: float) -> void:
	var t: float = clampf(lateral_friction * delta, 0.0, 1.0)
	var v := sphere.linear_velocity
	v.x = lerpf(v.x, 0.0, t)
	sphere.linear_velocity = v


func _orient_visual_to_run_direction(downhill: Vector3) -> void:
	var run_h := Vector3(downhill.x, 0.0, downhill.z)
	if run_h.length_squared() < 0.0001:
		run_h = Vector3(0, 0, 1)
	else:
		run_h = run_h.normalized()

	var up := Vector3.UP
	var forward := run_h

	if raycast.is_colliding():
		var n := raycast.get_collision_normal()
		normal = n
		if n.dot(Vector3.UP) > 0.25:
			up = n
		forward = run_h - up * run_h.dot(up)
		if forward.length_squared() < 0.0001:
			forward = up.cross(Vector3.RIGHT)
		if forward.length_squared() < 0.0001:
			forward = up.cross(Vector3.FORWARD)
		forward = forward.normalized()
	else:
		normal = Vector3.UP

	var pos = visual_model.global_position
	visual_model.look_at(pos + forward, up)
	if absf(visual_yaw_offset) > 0.0001:
		visual_model.rotate_object_local(Vector3.UP, -visual_yaw_offset)


func _on_sphere_body_entered(_body: Node) -> void:
	print("_on_sphere_body_entered")
	if visual_model == null:
		return
