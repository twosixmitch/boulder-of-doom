class_name GameUI extends Node

@export var prop_points_scene: PackedScene
@export var points_parent: Control

@export var coins_label: Label
@export var score_label: Label


func setup():
	score_label.text = "0"
	coins_label.text = "0"


func update_score(new_score: int) -> void:
	score_label.text = "%d" % new_score


func update_coins(new_coins: int) -> void:
	coins_label.text = "%d" % new_coins


func display_point(amount: int, world_position: Vector3) -> void:
	var points_node := prop_points_scene.instantiate() as PropPoints
	points_parent.add_child(points_node)
	points_node.setup(amount, world_position)


func _on_back_button_pressed():
	Events.game_exited.emit()
