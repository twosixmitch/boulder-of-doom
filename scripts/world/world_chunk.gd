class_name WorldChunk extends Node3D

## Marker for where the next chunk's origin (0,0,0) should align in world space.
## Chunk root is the start; this node's position (usually local +Z) defines length and connection.
@export var end_connection: Node3D


func get_start_global() -> Vector3:
	return global_position


func get_end_global() -> Vector3:
	if end_connection != null:
		return end_connection.global_position
	return global_position


## Forward extent from chunk origin to end connection, in chunk local space (+Z along the run).
func get_forward_span_local() -> float:
	if end_connection != null:
		return end_connection.position.z
	return 0.0
