extends Node
## Central input layer (autoload "InputReader").
## The ONLY place that reads raw input actions. Every system queries intents here instead
## of calling Input.* directly, so rebinding/suppression stay in one place. See docs/roadmap.md M4.

## Action name constants (must match project.godot [input]).
const ACT_UP: StringName = &"move_up"
const ACT_DOWN: StringName = &"move_down"
const ACT_LEFT: StringName = &"move_left"
const ACT_RIGHT: StringName = &"move_right"
const ACT_RUN: StringName = &"run"
const ACT_INTERACT: StringName = &"interact"
const ACT_LAMP: StringName = &"lamp_toggle"
const ACT_HIDE: StringName = &"hide"
const ACT_PAUSE: StringName = &"pause"
const ACT_UI_CONFIRM: StringName = &"ui_confirm"
const ACT_UI_CANCEL: StringName = &"ui_cancel"

## When false, gameplay intents report neutral/false (e.g. during cutscenes or menus).
var gameplay_enabled: bool = true


## Normalized-ish movement direction from the four move actions. Zero when disabled.
func get_move_vector() -> Vector2:
	if not gameplay_enabled:
		return Vector2.ZERO
	return Input.get_vector(ACT_LEFT, ACT_RIGHT, ACT_UP, ACT_DOWN)


## Pure mapping helper (unit-testable without the input system).
static func compute_move_vector(left: float, right: float, up: float, down: float) -> Vector2:
	var v := Vector2(right - left, down - up)
	if v.length() > 1.0:
		v = v.normalized()
	return v


func is_run_held() -> bool:
	return gameplay_enabled and Input.is_action_pressed(ACT_RUN)


func just_interacted() -> bool:
	return gameplay_enabled and Input.is_action_just_pressed(ACT_INTERACT)


func just_toggled_lamp() -> bool:
	return gameplay_enabled and Input.is_action_just_pressed(ACT_LAMP)


func just_hid() -> bool:
	return gameplay_enabled and Input.is_action_just_pressed(ACT_HIDE)


## Pause is intentionally NOT gated by gameplay_enabled so menus can always be toggled.
func just_paused() -> bool:
	return Input.is_action_just_pressed(ACT_PAUSE)


## UI intents are always available (menus run while gameplay input is disabled).
func ui_confirmed() -> bool:
	return Input.is_action_just_pressed(ACT_UI_CONFIRM)


func ui_cancelled() -> bool:
	return Input.is_action_just_pressed(ACT_UI_CANCEL)


func set_gameplay_enabled(enabled: bool) -> void:
	gameplay_enabled = enabled
