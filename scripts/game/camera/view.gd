extends Node3D

@export_group("What to follow")
## Scene node whose position we track. It must implement `get_player_position()` → `Vector3`.
@export var target: Node3D

@export_group("Follow behavior")
## How quickly the camera catches up to the player. Higher feels tighter; lower feels floaty.
@export_range(0.1, 30.0, 0.1) var follow_sharpness: float = 4.0

@export_group("How far the camera sits")
## Distance behind the player along the camera rig's local -Z (typical "pull the camera back").
@export_range(0.5, 80.0, 0.1) var distance_behind_player: float = 4.0
## How quickly the camera moves when this distance changes. Higher snaps; lower eases.
@export_range(0.1, 30.0, 0.1) var zoom_sharpness: float = 0.5

@export_group("When moving fast (optional)")
## If the target has a `linear_velocity` property, add extra distance while speed is high.
@export var pull_back_when_moving_fast: bool = false
## Speed (units per second) where the camera reaches the full extra distance.
@export_range(0.5, 80.0, 0.1) var speed_for_full_extra_distance: float = 12.0
## How much farther back the camera goes at full speed (added on top of distance behind player).
@export_range(0.0, 40.0, 0.1) var extra_distance_when_moving_fast: float = 2.0

@onready var camera: Camera3D = $Camera


func _physics_process(delta: float) -> void:
	if target == null or camera == null:
		return

	var follow_point: Vector3 = target.get_player_position()
	position = position.lerp(follow_point, delta * follow_sharpness)

	var target_distance: float = distance_behind_player
	if pull_back_when_moving_fast and "linear_velocity" in target:
		var speed: float = target.linear_velocity.length()
		var speed_t: float = clampf(speed / speed_for_full_extra_distance, 0.0, 1.0)
		target_distance += extra_distance_when_moving_fast * speed_t

	camera.position.z = lerpf(camera.position.z, -target_distance, delta * zoom_sharpness)
