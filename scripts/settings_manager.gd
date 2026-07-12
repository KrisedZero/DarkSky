extends Node
## Settings persistence (autoload "SettingsManager").
## Stores player-facing options (audio bus volumes) in user://settings.json and
## applies them on startup. Volumes are linear 0..1 and delegated to AudioManager.
## See docs/roadmap.md M24.

const SAVE_PATH: String = "user://settings.json"

var music_volume: float = 1.0
var ambient_volume: float = 1.0
var sfx_volume: float = 1.0
var ui_volume: float = 1.0


func _ready() -> void:
	load_settings()
	_apply_all()


## Persist current values to disk.
func save_settings() -> void:
	var data := {
		"music": music_volume,
		"ambient": ambient_volume,
		"sfx": sfx_volume,
		"ui": ui_volume,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SettingsManager: failed to save settings (%d)" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(data))
	f.close()


## Load values from disk, falling back to defaults when absent/corrupt.
func load_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	if text.is_empty():
		return
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return
	var d := data as Dictionary
	music_volume = float(d.get("music", music_volume))
	ambient_volume = float(data.get("ambient", ambient_volume))
	sfx_volume = float(data.get("sfx", sfx_volume))
	ui_volume = float(data.get("ui", ui_volume))


## Set a single bus volume (linear 0..1) and persist the change.
func set_volume(bus: String, linear: float) -> void:
	set_volume_live(bus, linear)
	save_settings()


## Set a bus volume live (updates memory + audio server) WITHOUT persisting (M28).
## The UI debounces persistence via save_settings() so dragging a slider doesn't thrash disk.
func set_volume_live(bus: String, linear: float) -> void:
	linear = clampf(linear, 0.0, 1.0)
	match bus:
		AudioManager.BUS_MUSIC:
			music_volume = linear
		AudioManager.BUS_AMBIENT:
			ambient_volume = linear
		AudioManager.BUS_SFX:
			sfx_volume = linear
		AudioManager.BUS_UI:
			ui_volume = linear
		_:
			push_error("SettingsManager: unknown bus '%s'" % bus)
			return
	AudioManager.set_bus_volume(bus, linear)


## Apply all cached volumes to the audio server.
func _apply_all() -> void:
	AudioManager.set_bus_volume(AudioManager.BUS_MUSIC, music_volume)
	AudioManager.set_bus_volume(AudioManager.BUS_AMBIENT, ambient_volume)
	AudioManager.set_bus_volume(AudioManager.BUS_SFX, sfx_volume)
	AudioManager.set_bus_volume(AudioManager.BUS_UI, ui_volume)
