class_name WorldManager extends Node

@export var player_controller: Node3D

#@export var terrain_chunk_scenes: Array[PackedScene] = [
	#preload("res://scenes/world/world_chunk_1.tscn"),
	#preload("res://scenes/world/world_chunk_2.tscn"),
	#preload("res://scenes/world/world_chunk_3.tscn"),
#]

@export var terrain_chunk_scenes: Array[PackedScene] = [
	preload("res://scenes/world/world_chunk_terraced_1.tscn"),
	preload("res://scenes/world/world_chunk_terraced_2.tscn"),
	preload("res://scenes/world/world_chunk_terraced_3.tscn"),
]

@export var chunks_ahead_buffer: int = 2
@export var chunks_behind_keep: int = 1

## Fallback span (world Z) for buffer/cleanup when no chunk has been measured yet.
@export var fallback_forward_span: float = 30.0

@export var spawn_pitch_deg: float = 22.0
@export var rotate_in_duration: float = 4.0

var _chunks: Array[WorldChunk] = []
## Next chunk is placed with its origin at this world position (previous chunk's end connection).
var _next_connection_global: Vector3 = Vector3.ZERO
## Next index in `terrain_chunk_scenes` (0 = chunk_1, 1 = chunk_2, 2 = chunk_3, then wraps).
var _next_chunk_pattern_index: int = 0


func _ready() -> void:
	_collect_existing_chunks()
	var scenes := _get_valid_chunk_scenes()
	if scenes.is_empty():
		push_error("WorldManager: assign at least one scene in terrain_chunk_scenes.")
		return

	if _chunks.is_empty():
		_next_connection_global = Vector3.ZERO
		_next_chunk_pattern_index = 0
		_spawn_chunk(false)
	else:
		_sort_chunks_by_start_z()
		var last_chunk := _chunks[_chunks.size() - 1]
		_next_connection_global = last_chunk.get_end_global()
		_next_chunk_pattern_index = _chunks.size() % scenes.size()

	_ensure_chunks_ahead(false)


func _process(_delta: float) -> void:
	if player_controller == null:
		return

	_ensure_chunks_ahead(true)
	_cleanup_old_chunks()


func _collect_existing_chunks() -> void:
	_chunks.clear()
	for child in get_children():
		if child is WorldChunk:
			_chunks.append(child as WorldChunk)


func _sort_chunks_by_start_z() -> void:
	_chunks.sort_custom(func(a: WorldChunk, b: WorldChunk) -> bool:
		return a.global_position.z < b.global_position.z
	)


func _ensure_chunks_ahead(animate_new_chunks: bool = true) -> void:
	if player_controller == null:
		return
		
	var player_pos := _get_player_position()

	var player_z := player_pos.z
	var buffer_z := _estimate_forward_buffer_z()
	var target_frontier_z := player_z + buffer_z

	while _get_last_chunk_end_z() < target_frontier_z:
		var end_z_before := _get_last_chunk_end_z()
		_spawn_chunk(animate_new_chunks)
		# Safety: zero-length chunk / bad end_connection would not advance the frontier.
		if _get_last_chunk_end_z() <= end_z_before + 0.0001:
			break


func _estimate_forward_span() -> float:
	if not _chunks.is_empty():
		var span := _chunks[_chunks.size() - 1].get_forward_span_local()
		if span > 0.001:
			return span
	return fallback_forward_span


func _estimate_forward_buffer_z() -> float:
	return _estimate_forward_span() * float(maxi(chunks_ahead_buffer, 1))


func _get_last_chunk_end_z() -> float:
	if _chunks.is_empty():
		return _next_connection_global.z
	return _chunks[_chunks.size() - 1].get_end_global().z


func _cleanup_old_chunks() -> void:
	if player_controller == null or _chunks.is_empty():
		return

	var keep_span := _estimate_forward_span() * float(maxi(chunks_behind_keep, 1))
	var min_keep_z := _get_player_position().z - keep_span

	for i in range(_chunks.size() - 1, -1, -1):
		var chunk := _chunks[i]
		if not is_instance_valid(chunk):
			_chunks.remove_at(i)
			continue
		if chunk.get_end_global().z < min_keep_z:
			chunk.queue_free()
			_chunks.remove_at(i)


func _spawn_chunk(animate_rotate_in: bool = true) -> void:
	var scenes := _get_valid_chunk_scenes()
	if scenes.is_empty():
		return

	var terrain_chunk_scene := scenes[_next_chunk_pattern_index % scenes.size()]
	if terrain_chunk_scene == null:
		return

	var inst := terrain_chunk_scene.instantiate()
	if not (inst is WorldChunk):
		if is_instance_valid(inst):
			inst.free()
		push_error("WorldManager: each terrain_chunk_scenes entry must be a WorldChunk root.")
		return

	var chunk := inst as WorldChunk
	add_child(chunk)
	chunk.global_position = _next_connection_global
	_chunks.append(chunk)
	_next_connection_global = chunk.get_end_global()
	_next_chunk_pattern_index = (_next_chunk_pattern_index + 1) % scenes.size()

	if animate_rotate_in:
		_animate_chunk_rotate_in(chunk)


func _get_valid_chunk_scenes() -> Array[PackedScene]:
	var out: Array[PackedScene] = []
	for s in terrain_chunk_scenes:
		if s != null:
			out.append(s)
	return out


func _animate_chunk_rotate_in(chunk: Node3D) -> void:
	if rotate_in_duration <= 0.0:
		return

	chunk.rotation_degrees.x = spawn_pitch_deg
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(chunk, "rotation_degrees:x", 0.0, rotate_in_duration)
	

func _get_player_position() -> Vector3:
	var player_pos := Vector3.ZERO
	if player_controller.has_method("get_player_position"):
		player_pos = player_controller.get_player_position()
	else:
		player_pos = player_controller.global_position
	return player_pos
	
