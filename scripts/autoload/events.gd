extends Node

@warning_ignore("unused_signal")
signal start_new_game

@warning_ignore("unused_signal")
signal game_exited
@warning_ignore("unused_signal")
signal game_complete(run_record: RunRecord, is_highscore: bool)

@warning_ignore("unused_signal")
signal results_complete

@warning_ignore("unused_signal")
signal hit_hazard(hazard_position: Vector3)
@warning_ignore("unused_signal")
signal hit_prop(prop_type: Enums.PropType, world_position: Vector3)
@warning_ignore("unused_signal")
signal hit_coin(coin_position: Vector3)

@warning_ignore("unused_signal")
signal player_steer_changed(axis: float)
@warning_ignore("unused_signal")
signal player_jump_requested
