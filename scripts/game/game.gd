class_name Game extends ScreenNode

@export var game_ui: GameUI
@export var player_controller: PlayerController

var current_score: int
var game_over: bool = false 


func _enter_tree():
	Events.hit_prop.connect(on_hit_prop)
	Events.hit_hazard.connect(on_hit_hazard)


func _exit_tree():
	Events.hit_prop.disconnect(on_hit_prop)
	Events.hit_hazard.disconnect(on_hit_hazard)
	

func on_screen_enter():
	pass


func on_hit_hazard(world_position: Vector3):
	if game_over:
		return
	player_controller.on_hit_hazard(world_position)
	print("on_hit_hazard")
	
	# Game over.
	game_over = true
	var current_highscore = GameStateService.get_highscore()
	if current_score > current_highscore:
		GameStateService.set_highscore(current_score)
		GameStateService.save_data()
	
	get_tree().create_timer(4.0).timeout.connect(func () -> void:
		Events.exit_game.emit()
	)


func on_hit_prop(_prop_type: Enums.PropType, world_position: Vector3):
	if game_over:
		return
	
	var point_value = 1
	current_score += point_value
	
	game_ui.update_score(current_score)
	game_ui.display_point(point_value, world_position)
