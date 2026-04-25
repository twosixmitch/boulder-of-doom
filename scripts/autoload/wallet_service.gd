extends Node

const DATA_DIR = "user://data"
const DATA_FILE_PATH = "user://data/wallet.dat"

var wallet: Wallet


func _ready() -> void:
	wallet = Wallet.new()


func get_coins() -> int:
	return wallet.coins


func add_coins(amount: int) -> void:
	wallet.coins += amount


func spend_coins(amount: int) -> bool:
	if wallet.coins < amount:
		return false
	
	wallet.coins -= amount
	return true


func load_data() -> void:
	wallet = Wallet.new()

	if not FileAccess.file_exists(DATA_FILE_PATH):
		print("[WalletService] No file exists")
		return

	var file = FileAccess.open(DATA_FILE_PATH, FileAccess.READ)

	if not file:
		var error = FileAccess.get_open_error()
		print("[WalletService] Load File Access Error: %s" % error)
		return

	var json_string = file.get_as_text()
	var json = JSON.new()

	var parse_result = json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return

	wallet.from_dictionary(json.get_data())


func save_data() -> void:
	if not DirAccess.dir_exists_absolute(DATA_DIR):
		var dir_error = DirAccess.make_dir_recursive_absolute(DATA_DIR)
		if dir_error != OK:
			printerr("[WalletService] Failed to make dir: %s, error: %s" % [DATA_DIR, dir_error])

	var file = FileAccess.open(DATA_FILE_PATH, FileAccess.WRITE)

	if not file:
		var error = FileAccess.get_open_error()
		print("[WalletService] Save File Access Error: %s" % error)
		return

	file.store_line(JSON.stringify(wallet.to_json()))
