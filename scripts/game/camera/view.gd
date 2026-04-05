extends Node3D

@export_group("Properties")
@export var target: PlayerCharacterController

@onready var camera = $Camera

# Functions

func _physics_process(delta):
	# Ease position towards target vehicle position
	
	self.position = self.position.lerp(target.get_player_position(), delta * 4)

	# Zoom camera based on the speed of the vehicle

	var speed_factor = clamp(abs(target.linear_speed), 0.0, 2.0)
	var target_z = remap(speed_factor, 0.0, 1.0, 8, 9)
	
	camera.position.z = lerp(camera.position.z, target_z * -1, delta * 0.5)
