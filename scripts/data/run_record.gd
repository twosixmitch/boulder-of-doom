class_name RunRecord

var score: int = 0
var props_hit: int = 0
var distance: float = 0.0


func to_json() -> Dictionary:
	return {
		"score": score,
		"props_hit": props_hit,
		"distance": distance,
	}


static func from_dictionary(data: Dictionary) -> RunRecord:
	var r := RunRecord.new()
	if data.get("score") is int:
		r.score = data["score"]
	if data.get("props_hit") is int:
		r.props_hit = data["props_hit"]
	if data.get("distance") is float or data.get("distance") is int:
		r.distance = float(data["distance"])
	return r
