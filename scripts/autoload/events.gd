extends Node

@warning_ignore("unused_signal")
signal start_new_game
@warning_ignore("unused_signal")
signal start_new_game_scene(scene_num: int)

@warning_ignore("unused_signal")
signal exit_game

@warning_ignore("unused_signal")
signal hit_hazard
@warning_ignore("unused_signal")
signal hit_prop(prop_type: Enums.PropType, world_position: Vector3)

@warning_ignore("unused_signal")
signal player_steer_changed(axis: float)
@warning_ignore("unused_signal")
signal player_jump_requested
