class_name HomeScreen extends ScreenNode

@export var highscore_label: Label
@export var coins_label: Label
@export var play_button: Control

var _screen_context: HomeScreenContext

func on_screen_enter(context: ScreenContext):
	if context:
		_screen_context = context as HomeScreenContext
		# Did we just come from a game? Should we display results?
	else:
		highscore_label.text = "%d" % GameStateService.get_highscore()
		coins_label.text = "%d" % WalletService.get_coins()
		play_button.visible = true


func _on_play_button_pressed():
	Events.start_new_game.emit()
