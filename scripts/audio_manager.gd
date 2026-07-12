extends Node
## Central audio controller (autoload). No hardcoded paths in gameplay code.
## Usage: AudioManager.play_sfx(AudioManager.Sfx.PICKUP)

enum Music { MENU, FLOOR }
enum Ambient { RAIN, WIND, FLOOR }
enum Sfx {
	FOOTSTEP_PLAYER, FOOTSTEP_MONSTER, HEARTBEAT, DETECTION,
	PICKUP, LANTERN_ON, LANTERN_OFF, DOOR_OPEN, DOOR_LOCK,
	UI_HOVER, UI_CONFIRM, GAME_OVER
}

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_AMBIENT := "Ambient"
const BUS_SFX := "SFX"
const BUS_UI := "UI"

var _music_map: Dictionary = {}
var _ambient_map: Dictionary = {}
var _sfx_map: Dictionary = {}

var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer]


func _ready() -> void:
	# Loaded at runtime (not preload) so the maps resolve even before Godot has (re)imported the
	# audio assets into .godot/imported; load() triggers import on demand and avoids parse-time
	# "Could not preload" failures on a stale/missing import cache.
	_music_map = {
		Music.MENU: load("res://assets/audio/music_menu.wav"),
		Music.FLOOR: load("res://assets/audio/music_floor.wav"),
	}
	_ambient_map = {
		Ambient.RAIN: load("res://assets/audio/ambient_rain.wav"),
		Ambient.WIND: load("res://assets/audio/ambient_wind.wav"),
		Ambient.FLOOR: load("res://assets/audio/ambient_floor.wav"),
	}
	_sfx_map = {
		Sfx.FOOTSTEP_PLAYER: load("res://assets/audio/sfx_footstep_player.wav"),
		Sfx.FOOTSTEP_MONSTER: load("res://assets/audio/sfx_footstep_monster.wav"),
		Sfx.HEARTBEAT: load("res://assets/audio/sfx_heartbeat.wav"),
		Sfx.DETECTION: load("res://assets/audio/sfx_detection.wav"),
		Sfx.PICKUP: load("res://assets/audio/sfx_pickup.wav"),
		Sfx.LANTERN_ON: load("res://assets/audio/sfx_lantern_on.wav"),
		Sfx.LANTERN_OFF: load("res://assets/audio/sfx_lantern_off.wav"),
		Sfx.DOOR_OPEN: load("res://assets/audio/sfx_door_open.wav"),
		Sfx.DOOR_LOCK: load("res://assets/audio/sfx_door_lock.wav"),
		Sfx.UI_HOVER: load("res://assets/audio/sfx_ui_hover.wav"),
		Sfx.UI_CONFIRM: load("res://assets/audio/sfx_ui_confirm.wav"),
		Sfx.GAME_OVER: load("res://assets/audio/sfx_game_over.wav"),
	}

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = BUS_AMBIENT
	add_child(_ambient_player)

	for i in 12:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_sfx_players.append(p)


func play_music(music: Music, fade_sec: float = 0.0) -> void:
	_music_player.stream = _music_map[music]
	if fade_sec > 0.0:
		_fade(_music_player, fade_sec, true)
	else:
		_music_player.volume_db = 0.0
		_music_player.play()


func stop_music(fade_sec: float = 0.0) -> void:
	if fade_sec > 0.0 and _music_player.playing:
		_fade(_music_player, fade_sec, false)
	else:
		_music_player.stop()


func play_ambient(ambient: Ambient, fade_sec: float = 0.0) -> void:
	_ambient_player.stream = _ambient_map[ambient]
	if fade_sec > 0.0:
		_fade(_ambient_player, fade_sec, true)
	else:
		_ambient_player.volume_db = 0.0
		_ambient_player.play()


func stop_ambient(fade_sec: float = 0.0) -> void:
	if fade_sec > 0.0 and _ambient_player.playing:
		_fade(_ambient_player, fade_sec, false)
	else:
		_ambient_player.stop()


func _fade(player: AudioStreamPlayer, fade_sec: float, fade_in: bool) -> void:
	if fade_in:
		player.volume_db = -80.0
		player.play()
		var tween := create_tween()
		tween.tween_property(player, "volume_db", 0.0, fade_sec)
	else:
		var tween := create_tween()
		tween.tween_property(player, "volume_db", -80.0, fade_sec)
		tween.tween_callback(player.stop)


func play_sfx(sfx: Sfx) -> void:
	var stream: AudioStream = _sfx_map[sfx]
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	_sfx_players[0].stream = stream
	_sfx_players[0].play()


func set_bus_volume(bus: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))


func get_bus_volume(bus: String) -> float:
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		return db_to_linear(AudioServer.get_bus_volume_db(idx))
	return 1.0
