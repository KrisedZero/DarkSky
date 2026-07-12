class_name Optimizer
extends RefCounted
## Pure optimization helpers (M26). No engine/node state required, so they are unit-testable
## and safe to call from any context. See docs/roadmap.md M26.

## True if `world_rect` intersects the camera's visible rect grown by `margin` px.
## The margin keeps nodes just off-screen visible until they are safely past the edge,
## avoiding pop-in at the viewport borders.
static func rect_visible(world_rect: Rect2, cam_rect: Rect2, margin: float = 32.0) -> bool:
	return world_rect.intersects(cam_rect.grow(margin))


## Cheap distance gate used by the monster AI: idle monsters beyond `range_px`
## can skip detection (gameplay stays correct because detection radius < range).
static func beyond_range(dist_px: float, range_px: float) -> bool:
	return dist_px > range_px
