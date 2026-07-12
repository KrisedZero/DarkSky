class_name MainMenu
extends Control
## Main menu (M23). New Game / Continue (enabled only when a save exists) / Exit.
## Wires to GameManager.start_game / continue_game. See docs/roadmap.md M23, docs/ui.md.
## Real forest/rain art is deferred to M28; this is a functional placeholder.

@onready var _title: Label = $VBox/Title
@onready var _play: Button = $VBox/PlayButton
@onready var _continue: Button = $VBox/ContinueButton
@onready var _settings: Button = $VBox/SettingsButton
@onready var _exit: Button = $VBox/ExitButton


func _ready() -> void:
	_play.pressed.connect(_on_play)
	_continue.pressed.connect(_on_continue)
	_settings.pressed.connect(_on_settings)
	_exit.pressed.connect(_on_exit)
	_refresh()
	_play.grab_focus()
	_bind_sfx()
	UISfx.apply_dark_theme(self)
	_apply_intro()


## Wire hover/confirm SFX onto every button (M28).
func _bind_sfx() -> void:
	UISfx.bind_button(_play)
	UISfx.bind_button(_continue)
	UISfx.bind_button(_settings)
	UISfx.bind_button(_exit)


## Intro juice (M28): animated dark backdrop (placeholder for forest/rain art) + title fade-in.
func _apply_intro() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.09)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.size = get_viewport_rect().size
	add_child(bg)
	move_child(bg, 0)
	var pulse := create_tween()
	pulse.set_loops(0)
	pulse.tween_property(bg, "modulate:a", 0.6, 2.0).from(0.9)
	pulse.tween_property(bg, "modulate:a", 0.9, 2.0)
	_title.modulate.a = 0.0
	_title.position.y -= 8
	var t := create_tween()
	t.tween_property(_title, "modulate:a", 1.0, 0.5)
	t.parallel().tween_property(_title, "position:y", _title.position.y + 8, 0.5)


func _refresh() -> void:
	_continue.disabled = not SaveManager.has_save()
	_title.text = (
		"PIXEL HORROR CASTLE"
		if not SaveManager.has_save()
		else "PIXEL HORROR CASTLE\nContinue available"
	)


func _on_play() -> void:
	GameManager.start_game()


func _on_continue() -> void:
	GameManager.continue_game()


func _on_settings() -> void:
	GameManager.open_settings()


func _on_exit() -> void:
	get_tree().quit()


func _unhandled_input(_event: InputEvent) -> void:
	if InputReader.ui_cancelled() and not GameManager._settings_open:
		get_tree().quit()
