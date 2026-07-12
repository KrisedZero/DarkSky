extends RefCounted
class_name UISfx
## UI sound + theme helpers (M28), so menus don't duplicate SFX/theme wiring.
## See docs/roadmap.md M28.

## Wire hover (mouse or keyboard focus) + confirm SFX onto a Button.
static func bind_button(btn: Button) -> void:
	if btn == null:
		return
	btn.mouse_entered.connect(func() -> void: AudioManager.play_sfx(AudioManager.Sfx.UI_HOVER))
	btn.focus_entered.connect(func() -> void: AudioManager.play_sfx(AudioManager.Sfx.UI_HOVER))
	btn.pressed.connect(func() -> void: AudioManager.play_sfx(AudioManager.Sfx.UI_CONFIRM))


## Build and assign a small dark "horror" Theme (StyleBoxFlat) to a Control at runtime.
## Code-only (no external art); gives the placeholder menus a less raw look.
static func apply_dark_theme(control: Control) -> void:
	if control == null:
		return
	var t := Theme.new()

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.14, 0.11, 0.18, 0.95)
	normal.border_color = Color(0.55, 0.18, 0.18, 1.0)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5
	t.set_stylebox("normal", "Button", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.34, 0.14, 0.14, 0.95)
	hover.border_color = Color(0.85, 0.32, 0.32, 1.0)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(4)
	hover.content_margin_left = 10
	hover.content_margin_right = 10
	hover.content_margin_top = 5
	hover.content_margin_bottom = 5
	t.set_stylebox("hover", "Button", hover)

	t.set_color("font_color", "Button", Color(0.95, 0.92, 0.9))

	var slider := StyleBoxFlat.new()
	slider.bg_color = Color(0.20, 0.16, 0.24, 1.0)
	slider.set_corner_radius_all(3)
	t.set_stylebox("normal", "HSlider", slider)

	control.theme = t
