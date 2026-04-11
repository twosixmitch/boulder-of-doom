class_name GameUI extends Node

@export var prop_points_scene: PackedScene

@export var score_label: Label
@export var points_parent: Control


func update_score(new_score: int) -> void:
	score_label.text = "%s" % new_score


func display_point(amount: int, world_position: Vector3) -> void:
	var points_node := prop_points_scene.instantiate() as PropPoints
	points_parent.add_child(points_node)
	points_node.setup(amount, world_position)


func _on_back_button_pressed():
	print("_on_back_button_pressed")
	Events.exit_game.emit()
