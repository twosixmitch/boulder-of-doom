extends Button

@export var tap_max_time_ms: int = 180
@export var tap_max_move_px: float = 24.0
@export var swipe_deadzone_px: float = 12.0
@export var max_swipe_px: float = 180.0

var _active_touch_id: int = -1
var _touch_start_pos: Vector2 = Vector2.ZERO
var _touch_current_pos: Vector2 = Vector2.ZERO
var _touch_start_time_ms: int = 0
var _steer_axis: float = 0.0
var _mouse_active: bool = false


func _ready() -> void:
	pressed.connect(_on_pressed)


func get_steer_axis() -> float:
	return _steer_axis


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
		return

	if event is InputEventScreenDrag:
		_handle_screen_drag(event)
		return

	if event is InputEventMouseButton:
		_handle_mouse_button(event)
		return

	if event is InputEventMouseMotion:
		_handle_mouse_motion(event)


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _active_touch_id != -1:
			return
		_active_touch_id = event.index
		_touch_start_pos = event.position
		_touch_current_pos = event.position
		_touch_start_time_ms = Time.get_ticks_msec()
		_set_steer_axis(0.0)
		return

	if event.index != _active_touch_id:
		return

	_touch_current_pos = event.position
	var move_dist := _touch_current_pos.distance_to(_touch_start_pos)
	var touch_elapsed_ms := Time.get_ticks_msec() - _touch_start_time_ms
	var is_tap := touch_elapsed_ms <= tap_max_time_ms and move_dist <= tap_max_move_px
	if is_tap:
		Events.player_jump_requested.emit()

	_reset_touch_state()


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index != _active_touch_id:
		return

	_touch_current_pos = event.position
	var delta_x := _touch_current_pos.x - _touch_start_pos.x
	var abs_delta_x := absf(delta_x)

	if abs_delta_x <= swipe_deadzone_px:
		_set_steer_axis(0.0)
		return

	var steer := clampf(-delta_x / maxf(max_swipe_px, 1.0), -1.0, 1.0)
	_set_steer_axis(steer)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		if _mouse_active:
			return
		_mouse_active = true
		_touch_start_pos = event.position
		_touch_current_pos = event.position
		_touch_start_time_ms = Time.get_ticks_msec()
		_set_steer_axis(0.0)
		return

	if not _mouse_active:
		return

	_touch_current_pos = event.position
	var move_dist := _touch_current_pos.distance_to(_touch_start_pos)
	var touch_elapsed_ms := Time.get_ticks_msec() - _touch_start_time_ms
	var is_tap := touch_elapsed_ms <= tap_max_time_ms and move_dist <= tap_max_move_px
	if is_tap:
		Events.player_jump_requested.emit()

	_mouse_active = false
	_reset_touch_state()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not _mouse_active:
		return

	_touch_current_pos = event.position
	var delta_x := _touch_current_pos.x - _touch_start_pos.x
	var abs_delta_x := absf(delta_x)

	if abs_delta_x <= swipe_deadzone_px:
		_set_steer_axis(0.0)
		return

	var steer := clampf(-delta_x / maxf(max_swipe_px, 1.0), -1.0, 1.0)
	_set_steer_axis(steer)


func _set_steer_axis(value: float) -> void:
	var next := clampf(value, -1.0, 1.0)
	if is_equal_approx(next, _steer_axis):
		return
	_steer_axis = next
	Events.player_steer_changed.emit(_steer_axis)


func _reset_touch_state() -> void:
	_active_touch_id = -1
	_mouse_active = false
	_touch_start_pos = Vector2.ZERO
	_touch_current_pos = Vector2.ZERO
	_touch_start_time_ms = 0
	_set_steer_axis(0.0)


func _exit_tree() -> void:
	_reset_touch_state()


func _on_pressed() -> void:
	# Ignore built-in button press handling. Gesture input is handled in `_gui_input`.
	pass
