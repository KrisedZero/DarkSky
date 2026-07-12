extends Node
## Screen-shake helper (M28). Call ScreenShake.add_trauma(amount) to shake the active camera.
## Trauma decays over time; the camera offset is random, scaled by trauma^2. When trauma reaches
## zero the offset is reset so the camera returns to its authored position. Safe when no camera
## exists (boot scenes): it simply decays without touching anything.

const MAX_OFFSET: float = 6.0
const DECAY: float = 1.5

var _trauma: float = 0.0


func add_trauma(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount)


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		return
	_trauma = maxf(0.0, _trauma - delta * DECAY)
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	if _trauma <= 0.0:
		cam.offset = Vector2.ZERO
		return
	var shake := _trauma * _trauma
	cam.offset = Vector2(
		randf_range(-1.0, 1.0) * MAX_OFFSET * shake,
		randf_range(-1.0, 1.0) * MAX_OFFSET * shake
	)
