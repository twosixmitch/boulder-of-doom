class_name PlayerController extends Node3D

# Nodes

@onready var sphere: RigidBody3D = $Sphere
@onready var raycast: RayCast3D = $Visuals/Mannequin_Medium/Ground
@onready var visual_model = $Visuals
@onready var _animation_tree: AnimationTree = $Visuals/Mannequin_Medium/AnimationTree

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


func start_running() -> void:
	_get_anim_playback().travel("running")


func start_idle() -> void:
	_get_anim_playback().travel("idle")


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

	_update_animation_speed()


func _log_grounded_changes() -> void:
	if not GameConfig.player_debug_jump_logs:
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

	var gravity_scale := GameConfig.player_rise_gravity_multiplier
	if sphere.linear_velocity.y < 0.0:
		gravity_scale = GameConfig.player_fall_gravity_multiplier

	var extra_scale := maxf(gravity_scale - 1.0, 0.0)
	if extra_scale <= 0.0:
		return

	var extra_force := Vector3.DOWN * _default_gravity * extra_scale * sphere.mass
	sphere.apply_central_force(extra_force)


func _course_forward() -> Vector3:
	if GameConfig.player_course_forward.length() > 0.001:
		return GameConfig.player_course_forward.normalized()
	return Vector3(0, 0, 1)


func _effective_forward_speed() -> float:
	if GameConfig.player_speed_ramp_duration <= 0.0:
		return GameConfig.player_max_speed
	var t := clampf(_speed_ramp_elapsed / GameConfig.player_speed_ramp_duration, 0.0, 1.0)
	return lerpf(GameConfig.player_starting_speed, GameConfig.player_max_speed, t)


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
	var desired_force: float = dv * GameConfig.player_forward_drive_strength * sphere.mass
	var clamped_force: float = clampf(desired_force, 0.0, GameConfig.player_max_forward_force)

	if clamped_force > 0.0:
		sphere.apply_force(course_forward * clamped_force)


func _clamp_lateral_speed() -> void:
	if not _player_controls_active:
		return

	if abs(sphere.linear_velocity.x) <= GameConfig.player_max_lateral_speed:
		return

	var v := sphere.linear_velocity
	v.x = sign(v.x) * GameConfig.player_max_lateral_speed
	sphere.linear_velocity = v


func _clamp_course_forward_speed(course_forward: Vector3) -> void:
	if not _player_controls_active:
		return

	var cap := _effective_forward_speed()
	if cap <= 0.0:
		return

	var v_forward := sphere.linear_velocity.dot(course_forward)
	if v_forward <= cap:
		return

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
		sphere.apply_force(Vector3(steer_axis * GameConfig.player_steer_force, 0.0, 0.0))
	else:
		_damp_lateral_motion(delta)


func _damp_lateral_motion(delta: float) -> void:
	var t: float = clampf(GameConfig.player_lateral_friction * delta, 0.0, 1.0)
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

	var combined := run_h + right_h * (steer_axis * GameConfig.player_steer_visual_blend)
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
	var fwd := forward.normalized()
	var fwd_flat := Vector3(fwd.x, 0.0, fwd.z)
	if fwd_flat.length_squared() < 1e-8:
		fwd_flat = Vector3(run_h.x, 0.0, run_h.z)
		if fwd_flat.length_squared() < 1e-8:
			fwd_flat = Vector3(0.0, 0.0, 1.0)
	fwd_flat = fwd_flat.normalized()
	var visual_right := Vector3.UP.cross(fwd_flat)
	if visual_right.length_squared() < 1e-8:
		visual_right = Vector3.RIGHT
	else:
		visual_right = visual_right.normalized()
	var up_vis := fwd.cross(visual_right).normalized()
	# glTF-style rigs: +Z forward — same as `Basis.looking_at(..., true)`.
	var b_face := Basis(visual_right, up_vis, fwd)
	var b_target := b_face * Basis.from_euler(Vector3(0.0, -GameConfig.player_visual_yaw_offset, 0.0))
	var q_target: Quaternion = b_target.get_rotation_quaternion()
	var q_current: Quaternion = visual_model.global_transform.basis.get_rotation_quaternion()
	var responsiveness := GameConfig.player_visual_rotation_responsiveness
	var blend: float = 1.0 if responsiveness <= 0.0 else 1.0 - exp(-responsiveness * delta)
	var q_smooth: Quaternion = q_current.slerp(q_target, blend)
	var preserved_scale: Vector3 = visual_model.global_transform.basis.get_scale()
	visual_model.global_transform = Transform3D(Basis(q_smooth).scaled(preserved_scale), pos)


func _get_anim_playback() -> AnimationNodeStateMachinePlayback:
	return _animation_tree.get("parameters/StateMachine/playback")


func _update_animation_speed() -> void:
	if _animation_tree == null:
		return
	var forward_speed := sphere.linear_velocity.dot(_course_forward())
	var speed_range := maxf(GameConfig.player_max_speed - GameConfig.player_starting_speed, 0.001)
	var t := clampf((forward_speed - GameConfig.player_starting_speed) / speed_range, 0.0, 1.0)
	_animation_tree.set("parameters/TimeScale/scale", lerpf(GameConfig.anim_run_speed_min, GameConfig.anim_run_speed_max, t))


func _on_player_steer_changed(axis: float) -> void:
	set_touch_steer_axis(axis)


func _on_player_jump_requested() -> void:
	var meets_conditions = raycast.is_colliding()

	if GameConfig.player_debug_jump_logs:
		print("[JumpDebug] jump_requested CAN=", meets_conditions, " y_vel=", sphere.linear_velocity.y)

	if meets_conditions:
		sphere.apply_central_impulse(Vector3.UP * GameConfig.player_jump_impulse * sphere.mass)
		_clamp_upward_linear_speed()


func _clamp_upward_linear_speed() -> void:
	if sphere.linear_velocity.y <= GameConfig.player_max_upward_speed:
		return
	var v := sphere.linear_velocity
	v.y = GameConfig.player_max_upward_speed
	sphere.linear_velocity = v


func _apply_hazard_knockback_recovery(delta: float) -> void:
	if _hazard_recovery_remaining <= 0.0:
		return

	var v := sphere.linear_velocity
	var horz := Vector3(v.x, 0.0, v.z)
	var horz_len_sq := horz.length_squared()
	if horz_len_sq > 1e-8:
		horz *= exp(-GameConfig.hazard_horizontal_damp * delta)
	v.x = horz.x
	v.z = horz.z

	if raycast.is_colliding():
		var damp_t: float = 1.0 - exp(-GameConfig.hazard_ground_vertical_damp * delta)
		v.y = lerpf(v.y, 0.0, damp_t)

	sphere.linear_velocity = v

	_hazard_recovery_remaining = maxf(_hazard_recovery_remaining - delta, 0.0)

	var speed_metric := horz.length() + absf(v.y)
	if speed_metric <= GameConfig.hazard_freeze_speed_threshold or _hazard_recovery_remaining <= 0.0:
		sphere.linear_velocity = Vector3.ZERO
		sphere.angular_velocity = Vector3.ZERO
		sphere.freeze = true
		_hazard_recovery_remaining = 0.0


func on_hit_hazard(hazard_position: Vector3) -> void:
	_player_controls_active = false
	sphere.freeze = false

	var cf := _course_forward()
	var from_hazard := sphere.global_position - hazard_position
	var knock_flat := Vector3(from_hazard.x, 0.0, from_hazard.z)
	if knock_flat.length_squared() < 1e-6:
		knock_flat = Vector3(-cf.x, 0.0, -cf.z)
		if knock_flat.length_squared() < 1e-6:
			knock_flat = Vector3(0.0, 0.0, -1.0)
	knock_flat = knock_flat.normalized()

	var v0 := sphere.linear_velocity
	var along := v0.dot(cf)
	if along > 0.0:
		v0 -= cf * along
	sphere.linear_velocity = v0

	await get_tree().process_frame

	sphere.apply_central_impulse(
		(knock_flat * GameConfig.hazard_knock_horizontal_impulse
		+ Vector3.UP * GameConfig.hazard_knock_vertical_impulse) * sphere.mass
	)

	_hazard_recovery_remaining = GameConfig.hazard_recovery_max_sec
