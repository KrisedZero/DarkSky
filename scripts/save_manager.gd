extends Node
## Save manager (autoload "SaveManager"). Autosaves on ascent (docs/save-system.md) as a JSON
## snapshot of the run seed, current floor, player stats, inventory and opened chest/door IDs.
## On load we rebuild the floor from the seed, then mark saved IDs opened so loot/locks are
## skipped (see docs/roadmap.md M16).
##
## Serialization is split from scene loading: serialize()/deserialize() move data only and are
## unit-testable; save_game()/load_game() add file I/O and trigger the floor rebuild + opened IDs.

const SAVE_PATH := "user://save.json"
const VERSION := 1

var _opened_chests: Dictionary = {}  # chest_id -> true (current floor)
var _opened_doors: Dictionary = {}  # door_id -> true (current floor)
var _restoring: bool = false
var _player_ref: Node = null
var _pending_player: Dictionary = {}  # applied on next player_spawned during restore


func _ready() -> void:
	SignalBus.player_spawned.connect(_on_player_spawned)
	SignalBus.chest_opened.connect(_on_chest_opened)
	SignalBus.door_opened.connect(_on_door_opened)
	SignalBus.floor_changed.connect(_on_floor_changed)


func _on_player_spawned(player: Node) -> void:
	_player_ref = player
	if _restoring and not _pending_player.is_empty():
		player.energy = float(_pending_player.get("energy", player.energy))
		player.lamp_oil = float(_pending_player.get("lamp_oil", player.lamp_oil))
		player.lamp_on = bool(_pending_player.get("lamp_on", player.lamp_on))
		player.set_hidden(int(_pending_player.get("state", 0)) == PlayerController.State.HIDDEN)
		_pending_player = {}


func _on_chest_opened(id: int) -> void:
	if not _restoring:
		_opened_chests[id] = true


func _on_door_opened(id: int) -> void:
	if not _restoring:
		_opened_doors[id] = true


func _on_floor_changed(_index: int) -> void:
	# A fresh floor starts with no opened interactables (unless we are mid-restore).
	if not _restoring:
		_opened_chests.clear()
		_opened_doors.clear()


## Build the save dictionary from current live state.
func serialize() -> Dictionary:
	var data: Dictionary = {}
	data["version"] = VERSION
	data["random_seed"] = GameManager.run_seed
	data["current_floor"] = GameManager.current_floor
	var player: Dictionary = {}
	if _player_ref != null and is_instance_valid(_player_ref):
		player["energy"] = _player_ref.energy
		player["lamp_oil"] = _player_ref.lamp_oil
		player["lamp_on"] = _player_ref.lamp_on
		player["state"] = _player_ref.state
	data["player"] = player
	data["inventory"] = InventoryManager.get_save_data()
	data["opened_chests"] = _opened_chests.keys()
	data["opened_doors"] = _opened_doors.keys()
	data["blood_codex_mode"] = InventoryManager.has_artifact(ItemsData.CODEX_BLOOD)
	return data


## Restore from a save dictionary. Sets _restoring so live open/player signals don't clobber it.
## Does NOT load the floor scene; the caller rebuilds it, then calls apply_opened_to_scene().
func deserialize(data: Dictionary) -> void:
	_restoring = true
	_opened_chests.clear()
	_opened_doors.clear()
	for id in data.get("opened_chests", []):
		_opened_chests[int(id)] = true
	for id in data.get("opened_doors", []):
		_opened_doors[int(id)] = true

	GameManager.run_seed = int(data.get("random_seed", 0))
	GameManager.current_floor = int(data.get("current_floor", 1))
	GameManager.state = GameManager.State.PLAYING

	InventoryManager.load_save_data(data.get("inventory", {}))

	_pending_player = data.get("player", {})


## Mark chests/doors in `root` as opened per the restored ID sets, then end restore mode.
func apply_opened_to_scene(root: Node) -> void:
	for chest in root.find_children("*", "Chest", true, false):
		if _opened_chests.has(chest.chest_id):
			chest.is_opened = true
			chest.interactable_enabled = false
	for door in root.find_children("*", "Door", true, false):
		if _opened_doors.has(door.door_id):
			door.is_locked = false
			door.is_open = true
			door.interactable_enabled = false
	_restoring = false


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var text := JSON.stringify(serialize())
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()


## Load the save and trigger the floor rebuild. Returns false if no save exists / unreadable.
func load_game() -> bool:
	if not has_save():
		return false
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	if text.is_empty():
		return false
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return false
	deserialize(data)
	if InventoryManager.has_artifact(ItemsData.CODEX_BLOOD):
		SignalBus.blood_mode_toggled.emit(true)
	SignalBus.game_started.emit()
	SignalBus.floor_changed.emit(GameManager.current_floor)
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
	_opened_chests.clear()
	_opened_doors.clear()
	_restoring = false
