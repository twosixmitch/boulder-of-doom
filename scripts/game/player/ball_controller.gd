extends RigidBody3D

## Simple mobile/keyboard steering for a rigidbody ball.
## Maps:
## - `ui_left`  -> steer left (arrow left / A depending on your input map)
## - `ui_right` -> steer right (arrow right / D depending on your input map)
@export var steer_force: float = 600.0
@export var max_lateral_speed: float = 1.2
@export var lateral_friction: float = 6.0

## Keep the ball rolling downhill by enforcing a minimum forward speed.
@export var downhill_dir: Vector3 = Vector3(0, 0, 1)
@export var min_forward_speed: float = 10.0
@export var forward_drive_strength: float = 2.0
@export var max_forward_force: float = 100.0
@export var max_downhill_speed: float = 15.0


func _physics_process(delta: float) -> void:
	var downhill := _downhill_direction()
	_apply_downhill_drive(downhill)

	_clamp_lateral_speed()
	_clamp_downhill_speed(downhill)

	_apply_lateral_control(delta)


func _downhill_direction() -> Vector3:
	if downhill_dir.length() > 0.001:
		return downhill_dir.normalized()
	return Vector3(0, 0, 1)


func _apply_downhill_drive(downhill: Vector3) -> void:
	if min_forward_speed <= 0.0:
		return
	
	var v_forward := linear_velocity.dot(downhill)
	if v_forward >= min_forward_speed:
		return
	
	var dv: float = min_forward_speed - v_forward
	var desired_force: float = dv * forward_drive_strength * mass
	var clamped_force: float = clampf(desired_force, 0.0, max_forward_force)
	
	if clamped_force > 0.0:
		apply_force(downhill * clamped_force)


func _clamp_lateral_speed() -> void:
	if abs(linear_velocity.x) <= max_lateral_speed:
		return
	
	var v := linear_velocity
	v.x = sign(v.x) * max_lateral_speed
	linear_velocity = v


func _clamp_downhill_speed(downhill: Vector3) -> void:
	if max_downhill_speed <= 0.0:
		return

	var v_forward := linear_velocity.dot(downhill)
	if v_forward <= max_downhill_speed:
		return
	
	linear_velocity += downhill * (max_downhill_speed - v_forward)


func _apply_lateral_control(delta: float) -> void:
	var steer_axis := -Input.get_axis("ui_left", "ui_right")
	
	if abs(steer_axis) > 0.001:
		apply_force(Vector3(steer_axis * steer_force, 0.0, 0.0))
	else:
		_damp_lateral_motion(delta)


func _damp_lateral_motion(delta: float) -> void:
	var t: float = clampf(lateral_friction * delta, 0.0, 1.0)
	var v := linear_velocity
	v.x = lerp(v.x, 0.0, t)
	linear_velocity = v
