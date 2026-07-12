class_name PauseMenu
extends Control
## Pause overlay (M24). Listens to game_paused / game_resumed and toggles itself.
## process_mode = PROCESS_MODE_WHEN_PAUSED (set in the scene) keeps it live while the
## tree is paused, so its buttons can resume play. See docs/roadmap.md M24.

@onready var _resume: Button = $Panel/VBox/ResumeButton
@onready var _settings: Button = $Panel/VBox/SettingsButton
@onready var _quit: Button = $Panel/VBox/QuitButton


func _ready() -> void:
	SignalBus.game_paused.connect(_on_paused)
	SignalBus.game_resumed.connect(_on_resumed)
	_resume.pressed.connect(_on_resume)
	_settings.pressed.connect(_on_settings)
	_quit.pressed.connect(_on_quit)
	UISfx.bind_button(_resume)
	UISfx.bind_button(_settings)
	UISfx.bind_button(_quit)
	UISfx.apply_dark_theme(self)
	visible = false


func _on_paused() -> void:
	visible = true
	_resume.grab_focus()


func _on_resumed() -> void:
	visible = false


func _on_resume() -> void:
	GameManager.resume()


func _on_settings() -> void:
	GameManager.open_settings()


func _on_quit() -> void:
	GameManager.return_to_menu()


func _unhandled_input(_event: InputEvent) -> void:
	if InputReader.ui_cancelled() and visible:
		GameManager.resume()
