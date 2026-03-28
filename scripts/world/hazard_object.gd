extends Node3D

@export var hazard_area: Area3D


func _ready():
	hazard_area.body_entered.connect(_on_body_entered)


func _on_body_entered(_body: Node3D):
	print("HAZARD _on_body_entered %s" % self.name)
