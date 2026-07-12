class_name FloorBuilder
extends RefCounted
## Assembles a generated FloorLayout into scene nodes: one Room per RoomData plus corridor floor
## strips, plus M30 world collision (visible walls + a static collision body) and returns the
## WorldGrid used for monster pathfinding. See docs/roadmap.md M12, M30.

const ROOM_SCENE := preload("res://scenes/Room.tscn")


## Build rooms + corridors + walls from `layout` into `container`. Returns a dict with keys:
## "rooms": Array[Room], "corridors": Array[TileMapLayer], "bounds_px": Rect2,
## "entrance_px": Vector2, "world_grid": WorldGrid.
func build(layout: FloorLayout, container: Node) -> Dictionary:
	for child in container.get_children():
		child.queue_free()

	var ts := FloorTileset.build()
	var grid := WorldGrid.from_layout(layout)

	var rooms: Array[Room] = []
	for rd in layout.rooms:
		var room := ROOM_SCENE.instantiate()
		room.position = Config.TILE_SIZE * rd.rect.position
		container.add_child(room)
		room.setup(rd, ts)
		rooms.append(room)

	var corridors: Array = []
	for cor in layout.corridors:
		var tml := TileMapLayer.new()
		tml.position = Config.TILE_SIZE * cor.position
		tml.tile_set = ts
		var w := int(cor.size.x)
		var h := int(cor.size.y)
		for y in h:
			for x in w:
				tml.set_cell(Vector2i(x, y), FloorTileset.TEX_CORRIDOR, Vector2i(0, 0))
		container.add_child(tml)
		corridors.append(tml)

	# M30: paint visible walls and a static collision body from the wall shell so the player and
	# monsters cannot walk through walls. The collision body uses horizontally-merged rectangles
	# (one StaticBody2D, many CollisionShape2D) which is cheap and seam-free for axis-aligned walls.
	var walls := TileMapLayer.new()
	walls.name = "Walls"
	walls.tile_set = WallTileset.build()
	var body := StaticBody2D.new()
	body.name = "Collision"
	for y in grid.rows:
		for x in grid.cols:
			var ax := x + grid.origin.x
			var ay := y + grid.origin.y
			if grid.is_wall_shell(ax, ay):
				walls.set_cell(Vector2i(ax, ay), 0, Vector2i(0, 0))
	_add_wall_collision(grid, body)
	container.add_child(walls)
	container.add_child(body)

	var b := layout.bounds()
	var bounds_px := Rect2(Config.TILE_SIZE * b.position, Config.TILE_SIZE * b.size)
	var entrance_px := Config.TILE_SIZE * layout.entrance_pos()
	return {
		"rooms": rooms, "corridors": corridors, "bounds_px": bounds_px,
		"entrance_px": entrance_px, "world_grid": grid
	}


## Build a single static collision body from horizontally-merged wall-shell rectangles.
func _add_wall_collision(grid: WorldGrid, body: StaticBody2D) -> void:
	var TILE := Config.TILE_SIZE
	var by_row: Dictionary = {}
	for y in grid.rows:
		for x in grid.cols:
			var ax := x + grid.origin.x
			var ay := y + grid.origin.y
			if grid.is_wall_shell(ax, ay):
				if not by_row.has(ay):
					by_row[ay] = []
				by_row[ay].append(ax)
	for y in by_row.keys():
		var xs: Array = by_row[y]
		xs.sort()
		xs.append(0x7FFFFFFF)  # sentinel to flush the final run
		var run_start := xs[0]
		var prev := xs[0]
		for i in range(1, xs.size()):
			if xs[i] == prev + 1:
				prev = xs[i]
			else:
				_add_wall_rect(body, run_start, y, prev - run_start + 1, TILE)
				run_start = xs[i]
				prev = xs[i]


func _add_wall_rect(body: StaticBody2D, tile_x: int, tile_y: int, tile_w: int, TILE: int) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(tile_w * TILE, TILE)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2((tile_x + tile_w * 0.5) * TILE, (tile_y + 0.5) * TILE)
	body.add_child(cs)


## Pure helper (unit-testable): room origin in pixels for a layout room.
static func room_origin_px(room: FloorLayout.RoomData) -> Vector2:
	return Config.TILE_SIZE * room.rect.position
