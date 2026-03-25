extends SpringArm3D

## Camera follower for a mobile "move forward down a hill" game.
## - No user orbit/input control
## - SpringArm rotation is fixed so the camera looks down +Z
## - SpringArm position follows the ball so the ball stays centered
@export var fixed_pitch_deg: float = -20.0
@export var fixed_yaw_deg: float = 180.0 # positions camera behind the ball when downhill is +Z
@export var follow_offset: Vector3 = Vector3(0, 1.2, 0) # relative to ball center
@export var follow_smoothing_hz: float = 40.0
@export var target_path: NodePath = NodePath("") # optional: path to the ball node

var _target: Node3D


func _ready() -> void:
	# Fixed orientation: no yaw/pitch changes during gameplay.
	rotation.x = deg_to_rad(fixed_pitch_deg)
	rotation.y = deg_to_rad(fixed_yaw_deg)
	rotation.z = 0.0

	# Resolve target (ball). By default, assume `ball` is a sibling of this SpringArm under `Player`.
	if target_path != NodePath(""):
		_target = get_node_or_null(target_path)
	if _target == null:
		var maybe_player := get_parent()
		if maybe_player:
			_target = maybe_player.get_node_or_null("ball")


func _physics_process(_delta: float) -> void:
	if _target == null:
		return

	var desired := _target.global_position + follow_offset

	# Exponential smoothing for stable mobile camera motion.
	# (Equivalent to lerp with a time-constant, independent of frame rate.)
	var t := 1.0 - exp(-follow_smoothing_hz * _delta)
	global_position = global_position.lerp(desired, t)
