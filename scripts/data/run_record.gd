class_name RunRecord

var score: int = 0
var coins_hit: int = 0
var props_hit: int = 0
var distance: int = 0


func to_json() -> Dictionary:
	return {
		"score": score,
		"coins_hit": coins_hit,
		"props_hit": props_hit,
		"distance": distance,
	}


static func from_dictionary(data: Dictionary) -> RunRecord:
	var r := RunRecord.new()
	if data.get("score"):
		r.score = data["score"] as int
	
	if data.get("coins_hit"):
		r.coins_hit = data["coins_hit"] as int
		
	if data.get("props_hit"):
		r.props_hit = data["props_hit"] as int
	
	if data.get("distance"):
		r.distance = data["distance"] as int
	
	return r
