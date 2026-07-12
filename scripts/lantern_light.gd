class_name LanternLight
extends PointLight2D
## The boy's lantern glow. A radial light that fades to darkness over a few tiles.
## Follows the player (attached under the LanternMarker) and switches with the lamp state.
## Radius comes from Config; the falloff is baked into a generated radial texture.

const TEXTURE_SIZE: int = 256

var _base_scale: float = 1.0
var _flicker_t: float = 0.0


func _ready() -> void:
	texture = _make_radial_texture()
	color = Config.LANTERN_COLOR
	_apply_radius()
	SignalBus.lamp_toggled.connect(_on_lamp_toggled)


func _on_lamp_toggled(is_on: bool) -> void:
	enabled = is_on


## Subtle lantern flicker (M28). Visual only — detection radius is read from Config separately in
## Monster.would_detect, so this never affects gameplay.
func _process(delta: float) -> void:
	if not enabled:
		return
	_flicker_t += delta
	var n := sin(_flicker_t * 12.0) * 0.5 + sin(_flicker_t * 7.7) * 0.5
	texture_scale = _base_scale * (1.0 + n * 0.03)
	color = Config.LANTERN_COLOR * (1.0 + n * 0.04)


func _apply_radius() -> void:
	_base_scale = Config.tiles_to_px(Config.LANTERN_RADIUS_TILES) / (float(TEXTURE_SIZE) * 0.5)
	texture_scale = _base_scale


## Convert a desired tile radius into the PointLight2D texture_scale for this texture size.
static func radius_to_scale(radius_px: float, texture_size: int) -> float:
	return radius_px / (float(texture_size) * 0.5)


func _make_radial_texture() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = TEXTURE_SIZE
	tex.height = TEXTURE_SIZE
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex
