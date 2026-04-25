extends Node

# =============================================================================
# Animation
# =============================================================================
## Animation TimeScale at player_starting_speed.
var anim_run_speed_min: float = 1.0
## Animation TimeScale at player_max_speed.
var anim_run_speed_max: float = 2.5

# =============================================================================
# Debug
# =============================================================================
var player_debug_jump_logs: bool = false

# =============================================================================
# Player Movement
# =============================================================================
var player_steer_force: float = 700.0
var player_max_lateral_speed: float = 1.4
var player_lateral_friction: float = 6.0
var player_course_forward: Vector3 = Vector3(0, 0, 1)
var player_starting_speed: float = 10.0
var player_max_speed: float = 20.0
## Seconds of play time to ramp from player_starting_speed to player_max_speed.
var player_speed_ramp_duration: float = 90.0
var player_forward_drive_strength: float = 2.0
var player_max_forward_force: float = 100.0
var player_jump_impulse: float = 10.0
## World +Y limit on sphere.linear_velocity (stops jump stacking on uneven normals).
var player_max_upward_speed: float = 13.0
var player_rise_gravity_multiplier: float = 1.5
var player_fall_gravity_multiplier: float = 4.0

# =============================================================================
# Player Visual
# =============================================================================
## Extra yaw around local Y after look_at (try ±TAU/4 if the rig faces sideways).
var player_visual_yaw_offset: float = 0.0
## How much lateral steer blends into the visual facing direction.
var player_steer_visual_blend: float = 0.45
## How quickly the visual catches the target facing. Higher = snappier.
var player_visual_rotation_responsiveness: float = 14.0

# =============================================================================
# Hazard Knockback
# =============================================================================
## Max seconds the knockback recovery lasts before force-stopping.
var hazard_recovery_max_sec: float = 3.0
## Higher = quicker horizontal slowdown on world XZ.
var hazard_horizontal_damp: float = 3.5
## When grounded during recovery, vertical motion eases toward rest.
var hazard_ground_vertical_damp: float = 5.0
var hazard_knock_horizontal_impulse: float = 6.0
var hazard_knock_vertical_impulse: float = 1.0
## Player stops recovering when speed falls at or below this threshold.
var hazard_freeze_speed_threshold: float = 0.4

# =============================================================================
# Game Rules
# =============================================================================
## Seconds after game over before returning to the home screen.
var game_over_delay_sec: float = 4.0
var prop_point_value: int = 1
## Maximum number of past runs kept in save data.
var max_run_history: int = 50

# =============================================================================
# World Generation
# =============================================================================
var world_chunks_ahead: int = 2
var world_chunks_behind_keep: int = 1
## Fallback span (world Z) used before any chunk has been measured.
var world_fallback_span: float = 30.0
## Leading entries in terrain_chunk_scenes that play only once (the start scene). Loop skips these.
var world_start_only_count: int = 1
## Pitch (degrees) chunks start at when they rotate into view.
var world_spawn_pitch_deg: float = 22.0
## Seconds for a new chunk to rotate from spawn pitch down to flat.
var world_rotate_in_duration: float = 4.0

# =============================================================================
# Camera
# =============================================================================
## How far behind the player the camera sits (world Z).
var camera_distance: float = 4.8
## Height of the camera above the player position.
var camera_height: float = 6.2
## Pitch in degrees — positive tilts the lens downward toward the player.
var camera_pitch_deg: float = -22.5

# =============================================================================
# Swipe Controls
# =============================================================================
var swipe_tap_max_time_ms: int = 180
var swipe_tap_max_move_px: float = 24.0
var swipe_deadzone_px: float = 12.0
var swipe_max_px: float = 180.0

# =============================================================================
# Props
# =============================================================================
## Seconds after activation before a prop moves to the Inactive Props layer.
var prop_collision_delay_sec: float = 0.6
var prop_vanish_duration: float = 0.4

# =============================================================================
# Coin
# =============================================================================
var coin_spin_speed: float = 1.0
var coin_bob_height: float = 0.15
var coin_bob_speed: float = 2.0

# =============================================================================
# Score Popup
# =============================================================================
var points_full_opacity_duration: float = 0.75
var points_fade_out_duration: float = 0.25
var points_world_offset: Vector3 = Vector3(0, 0.6, 0)
var points_rise_pixels: float = 80.0
var points_rise_duration: float = 0.5
