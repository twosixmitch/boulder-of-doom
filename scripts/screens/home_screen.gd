class_name HomeScreen extends ScreenNode

@export var highscore_label: Label
@export var coins_label: Label


func on_screen_enter():
	highscore_label.text = "%d" % GameStateService.get_highscore()
	coins_label.text = "%d" % WalletService.get_coins()


func _on_play_button_pressed():
	Events.start_new_game.emit()
