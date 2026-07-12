class_name WorldGrid
extends RefCounted
## Walkable grid derived from a FloorLayout (M30). Drives both world collision authoring
## (FloorBuilder paints walls from it) and monster A* pathfinding (Pathfinder).
## Tile coordinates are absolute (matching FloorLayout room/corridor rects); an origin offset
## keeps the internal index space non-negative.

var origin: Vector2i = Vector2i.ZERO
var cols: int = 0
var rows: int = 0
var cells: PackedByteArray = PackedByteArray()  # 1 = floor (walkable), 0 = wall
var _blocked: Dictionary = {}                    # Vector2i -> true (dynamic, e.g. closed doors)

const _BORDER: int = 2


static func from_layout(layout: FloorLayout) -> WorldGrid:
	var g := WorldGrid.new()
	var min_x := 0
	var min_y := 0
	var max_x := 0
	var max_y := 0
	for r in layout.rooms:
		min_x = mini(min_x, int(r.rect.position.x))
		min_y = mini(min_y, int(r.rect.position.y))
		max_x = maxi(max_x, int(r.rect.end.x))
		max_y = maxi(max_y, int(r.rect.end.y))
	for c in layout.corridors:
		min_x = mini(min_x, int(c.position.x))
		min_y = mini(min_y, int(c.position.y))
		max_x = maxi(max_x, int(c.end.x))
		max_y = maxi(max_y, int(c.end.y))
	g.origin = Vector2i(min_x - _BORDER, min_y - _BORDER)
	var end_x := max_x + _BORDER
	var end_y := max_y + _BORDER
	g.cols = end_x - g.origin.x
	g.rows = end_y - g.origin.y
	g.cells = PackedByteArray()
	g.cells.resize(g.cols * g.rows)
	for r in layout.rooms:
		g._fill_rect(r.rect, 1)
	for c in layout.corridors:
		g._fill_rect(c, 1)
	return g


func _fill_rect(rect: Rect2, value: int) -> void:
	var x0 := int(floor(rect.position.x))
	var y0 := int(floor(rect.position.y))
	var x1 := int(ceil(rect.end.x))
	var y1 := int(ceil(rect.end.y))
	for y in range(y0, y1):
		for x in range(x0, x1):
			_set_cell(x, y, value)


func _idx(x: int, y: int) -> int:
	return (y - origin.y) * cols + (x - origin.x)


func _set_cell(x: int, y: int, value: int) -> void:
	if x < origin.x or y < origin.y or x >= origin.x + cols or y >= origin.y + rows:
		return
	cells[_idx(x, y)] = value


## Raw floor membership (ignores dynamic door blocking).
func is_floor_tile(tile: Vector2i) -> bool:
	if tile.x < origin.x or tile.y < origin.y or tile.x >= origin.x + cols or tile.y >= origin.y + rows:
		return false
	return cells[_idx(tile.x, tile.y)] == 1


## Walkable = floor AND not dynamically blocked (e.g. by a closed door).
func is_walkable_tile(tile: Vector2i) -> bool:
	if not is_floor_tile(tile):
		return false
	return not _blocked.has(tile)


func is_blocked(tile: Vector2i) -> bool:
	return _blocked.has(tile)


func set_blocked(tile: Vector2i, blocked: bool) -> void:
	if blocked:
		_blocked[tile] = true
	else:
		_blocked.erase(tile)


## True if this wall cell borders at least one floor cell (the visible/colliding wall shell).
func is_wall_shell(x: int, y: int) -> bool:
	if is_floor_tile(Vector2i(x, y)):
		return false
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			if is_floor_tile(Vector2i(x + dx, y + dy)):
				return true
	return false


func world_to_tile(pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(pos.x / Config.TILE_SIZE)),
		int(floor(pos.y / Config.TILE_SIZE))
	)


func tile_to_world_center(tile: Vector2i) -> Vector2:
	return Vector2(
		(tile.x + 0.5) * Config.TILE_SIZE,
		(tile.y + 0.5) * Config.TILE_SIZE
	)


## Nearest walkable tile to `tile` (ring search), or `tile` unchanged if already walkable/in-bounds.
func nearest_walkable(tile: Vector2i) -> Vector2i:
	if is_walkable_tile(tile):
		return tile
	for radius in range(1, 25):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if abs(dx) != radius and abs(dy) != radius:
					continue
				var t := tile + Vector2i(dx, dy)
				if is_walkable_tile(t):
					return t
	return tile
