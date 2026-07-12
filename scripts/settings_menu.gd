class_name SettingsMenu
extends Control
## Settings overlay (M24). Sliders drive SettingsManager, which persists volumes to
## user://settings.json and applies them through AudioManager. Listens to settings_opened /
## settings_closed so it can show/hide over either the pause menu or the main menu.
## process_mode = PROCESS_MODE_WHEN_PAUSED keeps it live while the tree is paused.

@onready var _music: HSlider = $Panel/VBox/MusicRow/MusicSlider
@onready var _ambient: HSlider = $Panel/VBox/AmbientRow/AmbientSlider
@onready var _sfx: HSlider = $Panel/VBox/SfxRow/SfxSlider
@onready var _ui: HSlider = $Panel/VBox/UiRow/UiSlider
@onready var _back: Button = $Panel/VBox/BackButton

var _save_timer: Timer


func _ready() -> void:
	_music.value_changed.connect(_on_music)
	_ambient.value_changed.connect(_on_ambient)
	_sfx.value_changed.connect(_on_sfx)
	_ui.value_changed.connect(_on_ui)
	_back.pressed.connect(_on_back)
	SignalBus.settings_opened.connect(_on_opened)
	SignalBus.settings_closed.connect(_on_closed)
	# Debounced persistence (M28): live volume is applied on every change, but the JSON is only
	# written after the slider settles for SAVE_DEBOUNCE_SEC.
	_save_timer = Timer.new()
	_save_timer.wait_time = SAVE_DEBOUNCE_SEC
	_save_timer.one_shot = true
	add_child(_save_timer)
	_save_timer.timeout.connect(_on_save_timeout)
	UISfx.bind_button(_back)
	UISfx.apply_dark_theme(self)
	visible = false
	_sync_from_manager()


## Seconds to wait after the last slider change before persisting to disk.
const SAVE_DEBOUNCE_SEC: float = 0.3


func _on_save_timeout() -> void:
	SettingsManager.save_settings()


func _debounce_save() -> void:
	_save_timer.start()


func _on_opened() -> void:
	_sync_from_manager()
	visible = true
	_music.grab_focus()


func _on_closed() -> void:
	visible = false


func _sync_from_manager() -> void:
	_music.value = SettingsManager.music_volume
	_ambient.value = SettingsManager.ambient_volume
	_sfx.value = SettingsManager.sfx_volume
	_ui.value = SettingsManager.ui_volume


func _on_music(v: float) -> void:
	SettingsManager.set_volume_live(AudioManager.BUS_MUSIC, v)
	_debounce_save()


func _on_ambient(v: float) -> void:
	SettingsManager.set_volume_live(AudioManager.BUS_AMBIENT, v)
	_debounce_save()


func _on_sfx(v: float) -> void:
	SettingsManager.set_volume_live(AudioManager.BUS_SFX, v)
	_debounce_save()


func _on_ui(v: float) -> void:
	SettingsManager.set_volume_live(AudioManager.BUS_UI, v)
	_debounce_save()


func _on_back() -> void:
	GameManager.close_settings()


func _unhandled_input(_event: InputEvent) -> void:
	if InputReader.ui_cancelled() and visible:
		GameManager.close_settings()
