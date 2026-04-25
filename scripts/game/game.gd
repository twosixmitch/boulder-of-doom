class_name Game extends ScreenNode

@export var game_ui: GameUI
@export var player_controller: PlayerController

var current_score: int
var game_over: bool = false
var _game_over_timer: SceneTreeTimer

var _props_hit: int = 0


func _enter_tree():
	Events.hit_prop.connect(on_hit_prop)
	Events.hit_hazard.connect(on_hit_hazard)
	Events.hit_coin.connect(on_hit_coin)


func _exit_tree():
	Events.hit_prop.disconnect(on_hit_prop)
	Events.hit_hazard.disconnect(on_hit_hazard)
	Events.hit_coin.disconnect(on_hit_coin)


func on_screen_enter():
	player_controller.start_running()


func on_hit_hazard(world_position: Vector3):
	if game_over:
		return
	
	player_controller.on_hit_hazard(world_position)

	game_over = true

	var run := RunRecord.new()
	run.score = current_score
	run.props_hit = _props_hit
	run.distance = player_controller.get_player_position().z
	GameStateService.add_run(run)

	var current_highscore = GameStateService.get_highscore()
	if current_score > current_highscore:
		GameStateService.set_highscore(current_score)

	GameStateService.save_data()

	_game_over_timer = get_tree().create_timer(GameConfig.game_over_delay_sec)
	_game_over_timer.timeout.connect(func() -> void:
		Events.exit_game.emit()
	)


func on_hit_prop(_prop_type: Enums.PropType, world_position: Vector3):
	if game_over:
		return

	_props_hit += 1
	var point_value = GameConfig.prop_point_value
	current_score += point_value

	game_ui.update_score(current_score)
	game_ui.display_point(point_value, world_position)


func on_hit_coin(_world_position: Vector3):
	pass
