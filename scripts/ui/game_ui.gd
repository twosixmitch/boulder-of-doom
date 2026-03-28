class_name GameUI extends Node

@export var prop_points_scene: PackedScene

@export var score_label: Label
@export var points_parent: Control

func _enter_tree():
	Events.score_changed.connect(_on_score_changed)
	Events.display_point.connect(_display_point)


func _exit_tree():
	Events.score_changed.disconnect(_on_score_changed)
	Events.display_point.disconnect(_display_point)


func _on_score_changed(new_score: int) -> void:
	score_label.text = "SCORE: %s" % new_score


func _display_point(amount: int, world_position: Vector3) -> void:
	var points_node := prop_points_scene.instantiate() as PropPoints
	points_parent.add_child(points_node)
	points_node.setup(amount, world_position)
