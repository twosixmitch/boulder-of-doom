extends Label
class_name PropPoints

var _anchor_world: Vector3

var full_opacity_duration: float = 0.75
var fade_out_duration: float = 0.25
var world_offset: Vector3 = Vector3(0, 0.6, 0)
var rise_pixels: float = 80.0
var rise_duration: float = 0.5


func setup(amount: int, world_position: Vector3) -> void:
	_anchor_world = world_position + world_offset
	text = "+%d" % amount
	modulate.a = 1.0
	call_deferred("_apply_initial_screen_position")
	# TODO: If the number is over 3 digits change the font size to 64


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
	var target_y := global_position.y - rise_pixels
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position:y", target_y, rise_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(full_opacity_duration)
	tween.chain()
	tween.set_parallel(false)
	tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)
	tween.finished.connect(queue_free, CONNECT_ONE_SHOT)
