extends Node3D

## Scene node whose position we track. It must implement `get_player_position()` → `Vector3`.
@export var target: Node3D

@onready var camera: Camera3D = $Camera


func _ready() -> void:
	if target != null and not target.has_method("get_player_position"):
		push_warning("view.gd: target '%s' has no get_player_position() method." % target.name)
	if camera != null:
		camera.position = Vector3(0.0, GameConfig.camera_height, -GameConfig.camera_distance)
		# Y=180 faces the camera toward the run direction (+Z). X pitch tilts it down toward the player.
		camera.rotation_degrees = Vector3(GameConfig.camera_pitch_deg, 180.0, 0.0)


func _physics_process(_delta: float) -> void:
	if target == null:
		return

	position = target.get_player_position()
