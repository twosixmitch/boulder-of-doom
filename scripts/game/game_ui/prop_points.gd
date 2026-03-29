extends Label
class_name PropPoints

var _anchor_world: Vector3

@export var full_opacity_duration: float = 2.0
@export var fade_out_duration: float = 0.45
@export var world_offset: Vector3 = Vector3(0, 0.6, 0)


func setup(amount: int, world_position: Vector3) -> void:
	_anchor_world = world_position + world_offset
	text = "+%d" % amount
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 1.0
	set_anchors_preset(PRESET_TOP_LEFT)
	call_deferred("_apply_initial_screen_position")


func _apply_initial_screen_position() -> void:
	await get_tree().process_frame
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		queue_free()
		return
	var to_point := _anchor_world - cam.global_position
	if to_point.dot(-cam.global_transform.basis.z) <= 0.0:
		queue_free()
		return
	var p: Vector2 = cam.unproject_position(_anchor_world)
	global_position = p - size * 0.5
	_start_fade_and_free()


func _start_fade_and_free() -> void:
	var tween := create_tween()
	tween.tween_interval(full_opacity_duration)
	tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)
	tween.tween_callback(queue_free)
