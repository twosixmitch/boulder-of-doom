extends Node

@export var content_parent: Node

func _ready():
	Events.start_new_game.connect(on_start_new_game)
	Events.game_exited.connect(on_game_exited)
	Events.game_complete.connect(on_game_complete)
	
	GameStateService.load_data()
	WalletService.load_data()
	
	go_to_home_screen(null)


func go_to_home_screen(context: ScreenContext):
	change_screen("res://scenes/home_screen.tscn", context)


func on_start_new_game():
	change_screen("res://scenes/game.tscn", null)


func on_game_exited():
	go_to_home_screen(null)


func on_game_complete(run_record: RunRecord, is_highscore: bool):
	var context = HomeScreenContext.new()
	context.run_record = run_record
	context.is_highscore = is_highscore
	
	go_to_home_screen(context)


func change_screen(path: String, context: ScreenContext):
	var packed = ResourceLoader.load(path)
	
	if not packed:
		printerr("Failed to load screen: %s" % path)
		return
	
	var screen_node = packed.instantiate() as ScreenNode
	
	for child in content_parent.get_children():
		child.queue_free()
	
	content_parent.add_child(screen_node)
	
	# Allow the system to resize content so calling `.size` returns valid data.
	await get_tree().process_frame
	
	screen_node.on_screen_enter(context)
