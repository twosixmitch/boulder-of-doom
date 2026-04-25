class_name Wallet

var coins: int = 0


func to_json() -> Dictionary:
	return { "coins": coins }


func from_dictionary(data: Dictionary) -> void:
	if data.get("coins"):
		coins = data["coins"] as int
