class_name GameCamera
extends Camera2D
## Follows a target (the player) and stays locked inside the floor bounds.
## Uses Camera2D's built-in limits for edge clamping so the view never shows outside the floor.
## See docs/architecture.md section 4 and docs/roadmap.md M6.

@export var follow_target_path: NodePath
@export var smoothing_enabled: bool = true

var _target: Node2D = null


func _ready() -> void:
	position_smoothing_enabled = smoothing_enabled
	if follow_target_path != NodePath(""):
		set_target(get_node_or_null(follow_target_path) as Node2D)
	make_current()


func set_target(target: Node2D) -> void:
	_target = target


## Lock the camera inside the given world-space rectangle (floor bounds).
func set_bounds(bounds: Rect2) -> void:
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.position.x + bounds.size.x)
	limit_bottom = int(bounds.position.y + bounds.size.y)


func _physics_process(_delta: float) -> void:
	if _target != null and is_instance_valid(_target):
		global_position = _target.global_position


## Pure clamp helper (unit-testable): keeps a view of `view_size` centered on `pos`
## fully inside `bounds`. Returns the clamped center position.
static func clamp_center(pos: Vector2, bounds: Rect2, view_size: Vector2) -> Vector2:
	var half := view_size * 0.5
	var min_c := bounds.position + half
	var max_c := bounds.position + bounds.size - half
	var mid := bounds.position + bounds.size * 0.5
	# If the floor is smaller than the view on an axis, center on the floor.
	var x := mid.x if min_c.x > max_c.x else clampf(pos.x, min_c.x, max_c.x)
	var y := mid.y if min_c.y > max_c.y else clampf(pos.y, min_c.y, max_c.y)
	return Vector2(x, y)
