class_name GameState

var current_highscore: int = 0


func to_json() -> Dictionary:
	return {
		"highscore": current_highscore,
	}


func from_dictionary(json_data: Dictionary) -> void:
	if "highscore" in json_data:
		current_highscore = json_data["highscore"] as int
