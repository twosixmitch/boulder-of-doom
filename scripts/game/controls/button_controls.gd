extends VBoxContainer

## Hold left/right to steer; mirrors `ball_controller` use of `ui_left` / `ui_right`.

func _exit_tree() -> void:
	_release_all()


func _on_left_button_button_down() -> void:
	Input.action_press("ui_left")


func _on_left_button_button_up() -> void:
	Input.action_release("ui_left")


func _on_right_button_button_down() -> void:
	Input.action_press("ui_right")


func _on_right_button_button_up() -> void:
	Input.action_release("ui_right")


func _release_all() -> void:
	Input.action_release("ui_left")
	Input.action_release("ui_right")
