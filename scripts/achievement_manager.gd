extends Node
## Achievement tracker (autoload "AchievementManager").
## Persists unlocked achievement ids to user://achievements.json so they survive
## across runs/sessions. M25 (Difficulty) uses it to award "bloodbringer"
## when the game is won in Blood Codex mode. See docs/roadmap.md M25.

const SAVE_PATH: String = "user://achievements.json"

## Canonical achievement ids. Add new ones here as milestones introduce them.
const BLOODBRINGER := &"bloodbringer"

var _unlocked: Dictionary = {}  # StringName -> true


func _ready() -> void:
	load_achievements()


## Load unlocked ids from disk (no-op if absent).
func load_achievements() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	if text.is_empty():
		return
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return
	var d := data as Dictionary
	_unlocked = {}
	for k in d.keys():
		_unlocked[StringName(k)] = d[k]


## Persist the current unlocked set to disk.
func save_achievements() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("AchievementManager: failed to save (%d)" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(_unlocked))
	f.close()


## True if the achievement was already unlocked.
func has(id: StringName) -> bool:
	return _unlocked.get(id, false)


## Unlock an achievement. Emits `achievement_unlocked` (for UI/toasts) and
## persists. Idempotent: re-unlocking does not re-emit or re-save.
func unlock(id: StringName) -> void:
	if _unlocked.get(id, false):
		return
	_unlocked[id] = true
	save_achievements()
	SignalBus.achievement_unlocked.emit(id)


## All unlocked ids (read-only snapshot).
func get_all() -> Array:
	return _unlocked.keys()


## Test support: clear all unlocked achievements and delete the save file.
func reset_for_testing() -> void:
	_unlocked.clear()
	if FileAccess.file_exists(SAVE_PATH):
		var dir := DirAccess.open("user://")
		if dir:
			dir.remove(SAVE_PATH.get_file())
