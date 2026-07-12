extends Node
## Overall game flow controller (autoload "GameManager").
## Starts the game, advances floors, handles win/lose, and triggers checkpoint saves.
## Delegates scene swapping to SceneLoader and broadcasts state via SignalBus.
## See docs/architecture.md section 2 and docs/roadmap.md M3.

enum State { MENU, PLAYING, PAUSED, GAME_OVER, WON }

var state: int = State.MENU
var current_floor: int = 0
var run_seed: int = 0  # stable per run; stored in save (M16) for reproducible floors
var _pre_pause_state: int = State.PLAYING
var _settings_open: bool = false
# Test seam (M29): when true, flow functions update state/signals but skip SceneLoader swaps so
# automated self-tests can drive a full run without freeing the boot node.
var test_mode: bool = false


func _ready() -> void:
	SignalBus.player_caught.connect(_on_player_caught)


## Toggle pause during active play. Pausing freezes the scene tree and disables gameplay input;
## the pause overlay (M24) listens to game_paused to show itself.
func pause() -> void:
	if state != State.PLAYING:
		return
	_pre_pause_state = state
	state = State.PAUSED
	InputReader.set_gameplay_enabled(false)
	get_tree().paused = true
	SignalBus.game_paused.emit()


## Open the settings overlay. Works from the pause menu (state already PAUSED) or the
## main menu (state MENU); in both cases gameplay is frozen so only the overlay reacts.
func open_settings() -> void:
	if _settings_open:
		return
	_settings_open = true
	SignalBus.settings_opened.emit()


## Close the settings overlay, returning to whatever menu was beneath it.
func close_settings() -> void:
	if not _settings_open:
		return
	_settings_open = false
	SignalBus.settings_closed.emit()


## Resume from pause, restoring the pre-pause play state.
func resume() -> void:
	if state != State.PAUSED:
		return
	state = _pre_pause_state
	InputReader.set_gameplay_enabled(true)
	get_tree().paused = false
	SignalBus.game_resumed.emit()


## Begin a new run from floor 1.
func start_game() -> void:
	SaveManager.delete_save()
	run_seed = randi()
	current_floor = 1
	state = State.PLAYING
	SignalBus.game_started.emit()
	SignalBus.floor_changed.emit(current_floor)
	_load_floor(current_floor)


## Resume an existing run from the save file (M23 "Continue"). Returns to a new game if no save.
func continue_game() -> void:
	if not SaveManager.load_game():
		start_game()
		return
	_load_floor(current_floor)


## Deterministic seed for a given floor within the current run.
func floor_seed(floor: int) -> int:
	return run_seed + floor * 1013


## Advance to the next floor, or trigger the win flow past the last floor.
func advance_floor() -> void:
	if state != State.PLAYING:
		return
	if current_floor >= Config.FLOOR_COUNT:
		_win()
		return
	current_floor += 1
	SignalBus.floor_changed.emit(current_floor)
	SignalBus.checkpoint_saved.emit(current_floor)
	SaveManager.save_game()
	_load_floor(current_floor)


## Called on catch (M19): a Survival Amulet absorbs one hit instead of Game Over.
func _on_player_caught() -> void:
	if InventoryManager.has_flag(ItemsData.LIFE_AMULET):
		InventoryManager.set_flag(ItemsData.LIFE_AMULET, false)
		SignalBus.player_shield_consumed.emit()
		return
	game_over()


## Called when the player is caught.
func game_over() -> void:
	if state != State.PLAYING:
		return
	state = State.GAME_OVER
	if not test_mode:
		InputReader.set_gameplay_enabled(false)
	AudioManager.play_sfx(AudioManager.Sfx.GAME_OVER)
	ScreenShake.add_trauma(1.0)
	SignalBus.game_over.emit()
	if not test_mode:
		_show_game_over_overlay()


## Show the Game Over overlay (M28). The overlay owns the return-to-menu so the floor scene is
## not swapped until the player has seen the feedback.
func _show_game_over_overlay() -> void:
	var scene := load("res://scenes/GameOverOverlay.tscn") as PackedScene
	var overlay := scene.instantiate()
	get_tree().root.add_child(overlay)


func return_to_menu() -> void:
	if get_tree().paused:
		get_tree().paused = false
	# Always restore gameplay input (a death screen disables it in game_over()).
	InputReader.set_gameplay_enabled(true)
	state = State.MENU
	current_floor = 0
	if not test_mode:
		SceneLoader.change_scene(Config.SCENE_MAIN_MENU)


func _win() -> void:
	state = State.WON
	# Bloodbringer: completing the run in Blood Codex mode (M25).
	if InventoryManager.has_artifact(ItemsData.CODEX_BLOOD):
		AchievementManager.unlock(AchievementManager.BLOODBRINGER)
	SignalBus.game_won.emit()
	if not test_mode:
		SceneLoader.change_scene(Config.SCENE_ENDING_PLACEHOLDER)


func _load_floor(_index: int) -> void:
	# Real floor generation arrives in M11+. For now load the placeholder floor scene.
	if test_mode:
		return
	SceneLoader.change_scene(Config.SCENE_FLOOR_PLACEHOLDER)
