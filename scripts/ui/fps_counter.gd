extends Label

@export var update_interval: float = 0.5   # seconds between updates
@export var show_physics_fps: bool = true

var _timer: float = 0.0
var _smoothed_fps: float = 0.0

func _ready():
	# Initialize with current FPS
	_smoothed_fps = Engine.get_frames_per_second()

func _process(delta):
	_timer += delta
	
	if _timer < update_interval:
		return
	
	_timer = 0.0
	
	# Get current FPS
	var current_fps = Engine.get_frames_per_second()
	
	# Light smoothing (prevents jittery numbers)
	_smoothed_fps = lerp(_smoothed_fps, current_fps, 0.5)
	
	if show_physics_fps:
		text = "FPS: %d\nPhysics: %d" % [
			int(_smoothed_fps),
			Engine.physics_ticks_per_second
		]
	else:
		text = "FPS: %d" % int(_smoothed_fps)
