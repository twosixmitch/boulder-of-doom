class_name HomeScreen extends ScreenNode

@export var highscore_label: Label
@export var coins_label: Label
@export var play_button: Control
@export var results_view: ResultsView

var _screen_context: HomeScreenContext


func _enter_tree():
	Events.results_complete.connect(on_results_complete)


func _exit_tree():
	Events.results_complete.disconnect(on_results_complete)


func on_screen_enter(context: ScreenContext):
	if context:
		_screen_context = context as HomeScreenContext
		if _screen_context.run_record:
			start_result_flow()
	else:
		highscore_label.text = "%d" % GameStateService.get_highscore()
		coins_label.text = "%d" % WalletService.get_coins()
		play_button.visible = true


func _on_play_button_pressed():
	Events.start_new_game.emit()


func start_result_flow():
	# Hide the play button
	play_button.visible = false
	
	# Show the results control
	var run_record   = _screen_context.run_record
	var is_highscore = _screen_context.is_highscore
	
	results_view.show_results(run_record, is_highscore)


func on_results_complete():
	# Show the play button
	play_button.visible = true
