class_name PlayerController extends Node3D

@export var ball: Node3D


func get_ball_position() -> Vector3:
	if ball != null and is_instance_valid(ball):
		return ball.global_position
	return global_position
