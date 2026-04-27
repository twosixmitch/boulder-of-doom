class_name ResultsView extends Node

@export var results_coins_container: Control
@export var results_score_container: Control

@export var results_coins_label: Label
@export var results_score_label: Label

# Player's game state
@export var player_highscore_label: Label
@export var player_coins_label: Label


func show_results(run_record: RunRecord, _is_highscore: bool):
	var current_coins_amount = WalletService.get_coins()
	var previous_coins_amount = current_coins_amount - run_record.coins_hit
	player_coins_label.text = "%d" % previous_coins_amount
	
	player_highscore_label.text = "%d" % GameStateService.get_highscore()
	results_score_label.text = "%d" % run_record.score

	results_coins_container.modulate.a = 0.0
	results_score_container.modulate.a = 0.0
	results_coins_container.visible = run_record.coins_hit > 0
	results_score_container.visible = true

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	if run_record.coins_hit > 0:
		results_coins_label.text = "+ %d" % run_record.coins_hit
		tween.tween_property(results_coins_container, "modulate:a", 1.0, 0.4)
		tween.tween_interval(1.5)
		tween.set_parallel(true)
		tween.tween_method(_set_coins_label, run_record.coins_hit, 0, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_method(_set_player_coins_label, previous_coins_amount, current_coins_amount, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.set_parallel(false)
		tween.tween_interval(0.3)
		tween.tween_property(results_coins_container, "modulate:a", 0.0, 0.3)

	tween.tween_property(results_score_container, "modulate:a", 1.0, 0.4)
	tween.tween_interval(1.5)
	tween.tween_property(results_score_container, "modulate:a", 0.0, 0.3)
	tween.tween_callback(Events.results_complete.emit)


func _set_coins_label(value: int) -> void:
	results_coins_label.text = "+ %d" % value


func _set_player_coins_label(value: int) -> void:
	player_coins_label.text = "%d" % value
