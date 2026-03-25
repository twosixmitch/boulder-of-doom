extends RigidBody3D

## Simple mobile/keyboard steering for a rigidbody ball.
## Maps:
## - `ui_left`  -> steer left (arrow left / A depending on your input map)
## - `ui_right` -> steer right (arrow right / D depending on your input map)
@export var steer_force: float = 45.0
@export var max_lateral_speed: float = 8.0
@export var lateral_friction: float = 8.0

## Keep the ball rolling downhill by enforcing a minimum forward speed.
## Your world is oriented so downhill is +Z (by default).
## If your ball actually moves in -Z, set this to (0, 0, -1).
@export var downhill_dir: Vector3 = Vector3(0, 0, 1)
@export var min_forward_speed: float = 4.0
@export var forward_drive_strength: float = 2.0 # higher = snaps back to min speed faster
@export var max_forward_force: float = 200.0 # safety clamp (N)

func _physics_process(delta: float) -> void:
	# Inverted so arrow directions match the intended on-screen steering.
	var steer_axis := -Input.get_axis("ui_left", "ui_right") # -1..1

	# Apply forward drive if the ball slows down (e.g., after impacts).
	# This only kicks in when `v.z` is below `min_forward_speed`.
	var downhill := downhill_dir
	if downhill.length() > 0.001:
		downhill = downhill.normalized()
	else:
		downhill = Vector3(0, 0, 1)

	# Forward speed along the configured downhill axis.
	var v_forward: float = linear_velocity.dot(downhill)
	if min_forward_speed > 0.0 and v_forward < min_forward_speed:
		var dv: float = min_forward_speed - v_forward
		var desired_force: float = dv * forward_drive_strength * mass
		var clamped_force: float = clamp(desired_force, 0.0, max_forward_force)
		if clamped_force > 0.0:
			apply_force(downhill * clamped_force)

	# Always clamp lateral speed so the ball doesn't drift too far sideways.
	var v: Vector3 = linear_velocity
	if abs(v.x) > max_lateral_speed:
		v.x = sign(v.x) * max_lateral_speed
		linear_velocity = v

	if abs(steer_axis) > 0.001:
		# With your map oriented so downhill is +Z, left/right steering is world X.
		apply_force(Vector3(steer_axis * steer_force, 0.0, 0.0))
	else:
		# When no input is pressed, reduce sideways velocity to keep the ball centered.
		var t: float = clamp(lateral_friction * delta, 0.0, 1.0)
		v = linear_velocity
		v.x = lerp(v.x, 0.0, t)
		linear_velocity = v
