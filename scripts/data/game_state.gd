class_name GameState

var current_highscore: int = 0
var run_history: Array[RunRecord] = []


func to_json() -> Dictionary:
	return {
		"highscore": current_highscore,
		"run_history": run_history.map(func(r: RunRecord) -> Dictionary: return r.to_json()),
	}


func from_dictionary(json_data: Dictionary) -> void:
	if json_data.get("highscore"):
		current_highscore = json_data["highscore"] as int
	run_history.clear()
	if json_data.get("run_history") is Array:
		for entry in json_data["run_history"]:
			if entry is Dictionary:
				run_history.append(RunRecord.from_dictionary(entry))
