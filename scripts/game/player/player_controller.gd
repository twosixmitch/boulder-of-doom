class_name PlayerController extends Node3D

# Nodes

@onready var sphere: RigidBody3D = $Sphere
@onready var raycast: RayCast3D = $Visuals/Mannequin_Medium/Ground
@onready var visual_model = $Visuals

const STEER_FORCE := 600.0
const MAX_LATERAL_SPEED := 1.2
const LATERAL_FRICTION := 6.0

const COURSE_FORWARD := Vector3(0, 0, 1)
const STARTING_SPEED := 10.0
const MAX_SPEED := 20.0

## Seconds of play time to ramp from `STARTING_SPEED` to `MAX_SPEED`.
const SPEED_RAMP_DURATION := 90.0
const FORWARD_DRIVE_STRENGTH := 2.0
const MAX_FORWARD_FORCE := 100.0
const JUMP_IMPULSE := 10.0
## World +Y limit on `sphere.linear_velocity` (stops jump stacking on uneven normals).
const MAX_UPWARD_LINEAR_SPEED := 13.0
const RISE_GRAVITY_MULTIPLIER := 1.5
const FALL_GRAVITY_MULTIPLIER := 4.0
const DEBUG_JUMP_LOGS := true

## Extra yaw around local **Y** after `look_at` (rarely needed; try ±TAU/4 if the rig faces sideways).
const VISUAL_YAW_OFFSET := 0.0
## How much lateral steer blends into the visual facing direction (XZ), relative to course forward.
const STEER_VISUAL_BLEND := 0.45
## How quickly the visual catches the target facing (higher = snappier). Uses exponential smoothing.
const VISUAL_ROTATION_RESPONSIVENESS := 14.0
## After a hazard hit, horizontal speed is damped exponentially until below freeze threshold or this time runs out.
const HAZARD_RECOVERY_MAX_SEC := 3.0
## Higher = quicker horizontal slowdown (world XZ).
const HAZARD_HORIZONTAL_DAMP := 3.5
## When grounded during recovery, vertical motion eases toward rest (roll-out feel).
const HAZARD_GROUND_VERTICAL_DAMP := 5.0
## Knock impulse on XZ from hazard → player direction; small separate up bump (mass cancels in apply_central_impulse).
const HAZARD_KNOCK_HORIZONTAL_IMPULSE := 4.0
const HAZARD_KNOCK_VERTICAL_IMPULSE := 1.0
## Freeze when speed is at or below this (XZ + abs(Y) heuristic).
const HAZARD_FREEZE_SPEED_THRESH := 0.4

var normal: Vector3 = Vector3.UP

var linear_velocity: Vector3
var prev_position: Vector3
var _speed_ramp_elapsed: float = 0.0
var _touch_steer_axis: float = 0.0
var _default_gravity: float = 9.8
var _was_grounded: bool = false

## When false (e.g. after hitting a hazard), forward drive, steering, and lateral limits stop applying.
var _player_controls_active: bool = true
var _hazard_recovery_remaining: float = 0.0

# Public Functions

func get_player_position() -> Vector3:
	if visual_model:
		return visual_model.global_position
	return Vector3.ZERO


func set_touch_steer_axis(value: float) -> void:
	_touch_steer_axis = clampf(value, -1.0, 1.0)


func _ready() -> void:
	if ProjectSettings.has_setting("physics/3d/default_gravity"):
		_default_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity"))


func _enter_tree() -> void:
	Events.player_steer_changed.connect(_on_player_steer_changed)
	Events.player_jump_requested.connect(_on_player_jump_requested)


func _exit_tree() -> void:
	Events.player_steer_changed.disconnect(_on_player_steer_changed)
	Events.player_jump_requested.disconnect(_on_player_jump_requested)


func _physics_process(delta: float) -> void:	
	# Over time we are speeding up the Player.
	_speed_ramp_elapsed += delta
	
	# Debug logs for helping tune jumping.
	_log_grounded_changes()
	
	_apply_jump_gravity_tuning()
	
	var course_forward := _course_forward()
	_accelerate_toward_target_speed(course_forward)

	_clamp_lateral_speed()
	_clamp_course_forward_speed(course_forward)

	_apply_lateral_control(delta)

	visual_model.position = sphere.position - Vector3(0, 0.65, 0)
	_orient_visual_to_run_direction(delta, course_forward, _steer_axis())
	_apply_hazard_knockback_recovery(delta)
	_clamp_upward_linear_speed()

	linear_velocity = (visual_model.position - prev_position) / delta
	prev_position = visual_model.position


func _log_grounded_changes() -> void:
	if not DEBUG_JUMP_LOGS:
		return
	
	var grounded := raycast.is_colliding()
	if grounded == _was_grounded:
		return
		
	_was_grounded = grounded
	if grounded:
		print("[JumpDebug] grounded=", grounded, " y_vel=", sphere.linear_velocity.y)
	else:
		print_rich("[color=yellow][JumpDebug] grounded=", grounded, " y_vel=", sphere.linear_velocity.y, "[/color]")
	

func _apply_jump_gravity_tuning() -> void:
	if raycast.is_colliding():
		return

	var gravity_scale := RISE_GRAVITY_MULTIPLIER
	if sphere.linear_velocity.y < 0.0:
		gravity_scale = FALL_GRAVITY_MULTIPLIER

	var extra_scale := maxf(gravity_scale - 1.0, 0.0)
	if extra_scale <= 0.0:
		return

	var extra_force := Vector3.DOWN * _default_gravity * extra_scale * sphere.mass
	sphere.apply_central_force(extra_force)


func _course_forward() -> Vector3:
	if COURSE_FORWARD.length() > 0.001:
		return COURSE_FORWARD.normalized()
	return Vector3(0, 0, 1)


func _effective_forward_speed() -> float:
	if SPEED_RAMP_DURATION <= 0.0:
		return MAX_SPEED
	var t := clampf(_speed_ramp_elapsed / SPEED_RAMP_DURATION, 0.0, 1.0)
	return lerpf(STARTING_SPEED, MAX_SPEED, t)


func _accelerate_toward_target_speed(course_forward: Vector3) -> void:
	if not _player_controls_active:
		return

	var target_speed := _effective_forward_speed()
	if target_speed <= 0.0:
		return

	var v_forward := sphere.linear_velocity.dot(course_forward)
	if v_forward >= target_speed:
		return

	var dv: float = target_speed - v_forward
	var desired_force: float = dv * FORWARD_DRIVE_STRENGTH * sphere.mass
	var clamped_force: float = clampf(desired_force, 0.0, MAX_FORWARD_FORCE)

	if clamped_force > 0.0:
		sphere.apply_force(course_forward * clamped_force)


func _clamp_lateral_speed() -> void:
	if not _player_controls_active:
		return

	# Sideways (world X) speed is already within the cap — nothing to do.
	if abs(sphere.linear_velocity.x) <= MAX_LATERAL_SPEED:
		return

	# Otherwise, trim only the X component so left/right speed never exceeds the max.
	var v := sphere.linear_velocity
	v.x = sign(v.x) * MAX_LATERAL_SPEED # keep moving left or right, just not faster than allowed
	sphere.linear_velocity = v


func _clamp_course_forward_speed(course_forward: Vector3) -> void:
	if not _player_controls_active:
		return

	# Max allowed speed along the run direction (ramps up over play time).
	var cap := _effective_forward_speed()
	if cap <= 0.0:
		return

	# How fast we're already going along that same direction (scalar).
	var v_forward := sphere.linear_velocity.dot(course_forward)
	if v_forward <= cap:
		return

	# Nudge velocity along the course axis so forward speed equals the cap, without changing other axes.
	sphere.linear_velocity += course_forward * (cap - v_forward)


func _steer_axis() -> float:
	if not _player_controls_active:
		return 0.0
	
	var keyboard_axis := -Input.get_axis("ui_left", "ui_right")
	return _touch_steer_axis if absf(_touch_steer_axis) > 0.001 else keyboard_axis


func _apply_lateral_control(delta: float) -> void:
	if not _player_controls_active:
		return

	var steer_axis := _steer_axis()

	if abs(steer_axis) > 0.001:
		sphere.apply_force(Vector3(steer_axis * STEER_FORCE, 0.0, 0.0))
	else:
		_damp_lateral_motion(delta)


func _damp_lateral_motion(delta: float) -> void:
	var t: float = clampf(LATERAL_FRICTION * delta, 0.0, 1.0)
	var v := sphere.linear_velocity
	v.x = lerpf(v.x, 0.0, t)
	sphere.linear_velocity = v


func _orient_visual_to_run_direction(delta: float, course_forward: Vector3, steer_axis: float = 0.0) -> void:
	var run_h := Vector3(course_forward.x, 0.0, course_forward.z)
	if run_h.length_squared() < 0.0001:
		run_h = Vector3(0, 0, 1)
	else:
		run_h = run_h.normalized()

	var right_h := Vector3.UP.cross(run_h)
	if right_h.length_squared() < 0.0001:
		right_h = Vector3.RIGHT
	else:
		right_h = right_h.normalized()

	var combined := run_h + right_h * (steer_axis * STEER_VISUAL_BLEND)
	if combined.length_squared() < 0.0001:
		combined = run_h
	else:
		combined = combined.normalized()
	run_h = combined

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

	var pos: Vector3 = visual_model.global_position
	# glTF-style rigs: +Z forward (`use_model_front`), same as `look_at(..., true)`.
	var b_face := Basis.looking_at(forward, up, true)
	var b_target := b_face * Basis.from_euler(Vector3(0.0, -VISUAL_YAW_OFFSET, 0.0))
	var q_target: Quaternion = b_target.get_rotation_quaternion()
	var q_current: Quaternion = visual_model.global_transform.basis.get_rotation_quaternion()
	var blend: float = 1.0 if VISUAL_ROTATION_RESPONSIVENESS <= 0.0 else 1.0 - exp(-VISUAL_ROTATION_RESPONSIVENESS * delta)
	var q_smooth: Quaternion = q_current.slerp(q_target, blend)
	var preserved_scale: Vector3 = visual_model.global_transform.basis.get_scale()
	visual_model.global_transform = Transform3D(Basis(q_smooth).scaled(preserved_scale), pos)


func _on_player_steer_changed(axis: float) -> void:
	set_touch_steer_axis(axis)


func _on_player_jump_requested() -> void:
	var meets_conditions = raycast.is_colliding()
	
	if DEBUG_JUMP_LOGS:
		print("[JumpDebug] jump_requested CAN=", meets_conditions, " y_vel=", sphere.linear_velocity.y)
	
	if meets_conditions:
		sphere.apply_central_impulse(Vector3.UP * JUMP_IMPULSE * sphere.mass)
		_clamp_upward_linear_speed()


func _clamp_upward_linear_speed() -> void:
	if sphere.linear_velocity.y <= MAX_UPWARD_LINEAR_SPEED:
		return
	var v := sphere.linear_velocity
	v.y = MAX_UPWARD_LINEAR_SPEED
	sphere.linear_velocity = v


func _apply_hazard_knockback_recovery(delta: float) -> void:
	if _hazard_recovery_remaining <= 0.0:
		return

	# Slow horizontal slip on XZ; Y still gets gravity from earlier in the frame, so the arc feels natural.
	var v := sphere.linear_velocity
	var horz := Vector3(v.x, 0.0, v.z)
	var horz_len_sq := horz.length_squared()
	if horz_len_sq > 1e-8:
		horz *= exp(-HAZARD_HORIZONTAL_DAMP * delta)
	v.x = horz.x
	v.z = horz.z

	if raycast.is_colliding():
		var damp_t: float = 1.0 - exp(-HAZARD_GROUND_VERTICAL_DAMP * delta)
		v.y = lerpf(v.y, 0.0, damp_t)

	sphere.linear_velocity = v

	_hazard_recovery_remaining = maxf(_hazard_recovery_remaining - delta, 0.0)

	var speed_metric := horz.length() + absf(v.y)
	if speed_metric <= HAZARD_FREEZE_SPEED_THRESH or _hazard_recovery_remaining <= 0.0:
		sphere.linear_velocity = Vector3.ZERO
		sphere.angular_velocity = Vector3.ZERO
		sphere.freeze = true
		_hazard_recovery_remaining = 0.0


func on_hit_hazard(hazard_position: Vector3) -> void:
	_player_controls_active = false
	sphere.freeze = false

	var cf := _course_forward()
	# Away from the hazard on the ground plane (world XZ); if we’re right on top of it, fall back to “back” along course.
	var from_hazard := sphere.global_position - hazard_position
	var knock_flat := Vector3(from_hazard.x, 0.0, from_hazard.z)
	if knock_flat.length_squared() < 1e-6:
		knock_flat = Vector3(-cf.x, 0.0, -cf.z)
		if knock_flat.length_squared() < 1e-6:
			knock_flat = Vector3(0.0, 0.0, -1.0)
	knock_flat = knock_flat.normalized()

	# Remove forward run speed so the hit reads as a rebound off the obstacle, not run speed + knock summed.
	var v0 := sphere.linear_velocity
	var along := v0.dot(cf)
	if along > 0.0:
		v0 -= cf * along
	sphere.linear_velocity = v0

	sphere.apply_central_impulse(
		(knock_flat * HAZARD_KNOCK_HORIZONTAL_IMPULSE + Vector3.UP * HAZARD_KNOCK_VERTICAL_IMPULSE) * sphere.mass
	)

	_hazard_recovery_remaining = HAZARD_RECOVERY_MAX_SEC
