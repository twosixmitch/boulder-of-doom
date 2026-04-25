extends Label
class_name PropPoints

var _anchor_world: Vector3


func setup(amount: int, world_position: Vector3) -> void:
	_anchor_world = world_position + GameConfig.points_world_offset
	text = "%d" % amount
	modulate.a = 1.0
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
	var target_y := global_position.y - GameConfig.points_rise_pixels
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position:y", target_y, GameConfig.points_rise_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(GameConfig.points_full_opacity_duration)
	tween.chain()
	tween.set_parallel(false)
	tween.tween_property(self, "modulate:a", 0.0, GameConfig.points_fade_out_duration)
	tween.finished.connect(queue_free, CONNECT_ONE_SHOT)
