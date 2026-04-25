extends Node

const DATA_DIR = "user://data"
const DATA_FILE_PATH = "user://data/game.dat"

var game_state: GameState


func _ready() -> void:
	game_state = GameState.new()


func get_highscore() -> int:
	return game_state.current_highscore


func set_highscore(new_highscore: int) -> void:
	game_state.current_highscore = new_highscore


func get_run_history() -> Array[RunRecord]:
	return game_state.run_history


func add_run(run: RunRecord) -> void:
	game_state.run_history.append(run)
	# Keep history capped so the save file doesn't grow unbounded.
	while game_state.run_history.size() > GameConfig.max_run_history:
		game_state.run_history.pop_front()


func load_data() -> void:
	game_state = GameState.new()
	
	if not FileAccess.file_exists(DATA_FILE_PATH):
		print("[GameStateService] No file exists")
		return
	
	var file = FileAccess.open(DATA_FILE_PATH, FileAccess.READ)
	
	if not file:
		var error = FileAccess.get_open_error()
		print("[GameStateService] Load File Access Error: %s" % error)
		return
	
	var json_string = file.get_as_text()
	var json = JSON.new()

	var parse_result = json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return

	var node_data = json.get_data()	
	game_state.from_dictionary(node_data)


func save_data() -> void:	
	if not DirAccess.dir_exists_absolute(DATA_DIR):
		var dir_error = DirAccess.make_dir_recursive_absolute(DATA_DIR)
		if dir_error != OK:
			printerr("[GameStateService] Failed to make dir: %s, error: %s" % [DATA_DIR, dir_error])
	
	var file = FileAccess.open(DATA_FILE_PATH, FileAccess.WRITE)
	
	if not file:
		var error = FileAccess.get_open_error()
		print("[GameStateService] Save File Access Error: %s" % error)
		return

	var json_data = JSON.stringify(game_state.to_json())
	file.store_string(json_data)
