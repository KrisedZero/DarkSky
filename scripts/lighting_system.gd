class_name LightingSystem
extends CanvasModulate
## Controls the floor's ambient darkness and the Blood Codex red filter.
## As a CanvasModulate it multiplies the whole 2D canvas; lantern lights add brightness on top.
## Reacts to SignalBus.blood_mode_toggled. See docs/roadmap.md M7 and art-style.md.

var _blood_active: bool = false


func _ready() -> void:
	_refresh()
	SignalBus.blood_mode_toggled.connect(_on_blood_mode_toggled)


func _on_blood_mode_toggled(active: bool) -> void:
	_blood_active = active
	_refresh()


func _refresh() -> void:
	color = apply_blood_tint(Config.AMBIENT_DARKNESS) if _blood_active else Config.AMBIENT_DARKNESS


## Pure helper (unit-testable): pushes an ambient color toward red for Blood Mode.
static func apply_blood_tint(base: Color) -> Color:
	return Color(minf(1.0, base.r * 3.0 + 0.25), base.g * 0.4, base.b * 0.4, base.a)
