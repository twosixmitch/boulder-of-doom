extends Node

@warning_ignore("unused_signal")
signal start_new_game

@warning_ignore("unused_signal")
signal exit_game


@warning_ignore("unused_signal")
signal score_changed(new_score: int)
@warning_ignore("unused_signal")
signal display_point(amount: int, world_position: Vector3)

@warning_ignore("unused_signal")
signal hit_hazard
