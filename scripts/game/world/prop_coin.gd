class_name PropCoin extends Node3D

@export var visuals: Node3D
var _activated: bool = false
var _bob_time: float = 0.0
var _base_visual_position: Vector3


func _on_body_entered(body):
	if _can_activate_from_body(body):
		activate()


func _on_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	if _can_activate_from_body(body):
		activate()


func _can_activate_from_body(body) -> bool:
	if _activated:
		return false

	if not body.is_in_group("player"):
		return false

	return true


func _ready():
	if visuals != null:
		_base_visual_position = visuals.position


func _process(delta):
	if visuals == null:
		return

	_bob_time += delta
	visuals.rotate_y(GameConfig.coin_spin_speed * delta)
	visuals.position = _base_visual_position + Vector3(0.0, sin(_bob_time * GameConfig.coin_bob_speed) * GameConfig.coin_bob_height, 0.0)


func activate():
	_activated = true
	Events.hit_coin.emit(self.global_position)
	call_deferred("queue_free")
