class_name Game extends ScreenNode

@export var game_ui: GameUI
@export var player_controller: PlayerController

var _current_score: int
var _game_over: bool = false
var _game_over_timer: SceneTreeTimer

var _props_hit: int = 0
var _coins_hit: int = 0


func _enter_tree():
	Events.hit_prop.connect(on_hit_prop)
	Events.hit_hazard.connect(on_hit_hazard)
	Events.hit_coin.connect(on_hit_coin)


func _exit_tree():
	Events.hit_prop.disconnect(on_hit_prop)
	Events.hit_hazard.disconnect(on_hit_hazard)
	Events.hit_coin.disconnect(on_hit_coin)


func on_screen_enter(_context: ScreenContext):
	player_controller.start_running()
	game_ui.setup()


func on_hit_hazard(world_position: Vector3):
	if _game_over:
		return
		
	_game_over = true
	
	player_controller.on_hit_hazard(world_position)

	var run := RunRecord.new()
	run.score = _current_score
	run.props_hit = _props_hit
	run.coins_hit = _coins_hit
	run.distance = roundi(player_controller.get_player_position().z)
	GameStateService.add_run(run)
	
	var is_highscore = GameStateService.update_highscore(_current_score)
	GameStateService.save_data()
	
	WalletService.add_coins(_coins_hit)
	WalletService.save_data()
	
	_game_over_timer = get_tree().create_timer(GameConfig.game_over_delay_sec)
	_game_over_timer.timeout.connect(func() -> void:
		Events.game_complete.emit(run, is_highscore)
	)


func on_hit_prop(_prop_type: Enums.PropType, world_position: Vector3):
	if _game_over:
		return

	_props_hit += 1
	var point_value = GameConfig.prop_point_value
	_current_score += point_value

	game_ui.update_score(_current_score)
	game_ui.display_point(point_value, world_position)


func on_hit_coin(_world_position: Vector3):
	_coins_hit += 1
	game_ui.update_coins(_coins_hit)
