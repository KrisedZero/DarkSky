class_name FloorGenerator
extends RefCounted
## Deterministic, seedable floor generator. Produces a FloorLayout (pure data) following
## docs/generation.md §1: 12–30 rooms as a connected tree, guaranteed Entrance->Stairs path,
## required Balcony/Bedroom types, and monster spawn points. No nodes are created here — Rooms (M12)
## turn this into a scene. Same seed+floor_index always yields the same layout (tested).
## See docs/roadmap.md M11.

const CELL_TILES := 11  # grid cell size in tiles (rooms stay inside, corridors between)
const CORRIDOR_WIDTH := 2
const MIN_ROOMS := 12
const MAX_ROOMS := 30


## Generate a floor. `seed` reproduces the layout; `floor_index` scales size/danger.
func generate(seed: int, floor_index: int) -> FloorLayout:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var target := clampi(MIN_ROOMS + floor_index * 2, MIN_ROOMS, MAX_ROOMS)

	var layout := FloorLayout.new()
	layout.seed = seed
	layout.floor_index = floor_index

	var grid_cols := 7
	var grid_rows := 7
	var visited: Dictionary = {}  # cell_key -> room_id
	var cell_of: Dictionary = {}  # room_id -> cell_key

	var order := _shuffle_cells(rng, grid_cols, grid_rows)
	var room_count := 0
	var prev_cell := -1
	for cell in order:
		if room_count >= target:
			break
		var room := FloorLayout.RoomData.new()
		room.id = room_count
		room.rect = _make_room_rect(rng, cell, grid_cols)
		layout.rooms.append(room)
		visited[cell] = room.id
		cell_of[room.id] = cell
		if prev_cell != -1 and visited.has(prev_cell):
			# Connect as a tree edge to the previous placed room (guarantees connectivity, no loops).
			layout.connections.append(
				PackedInt32Array([prev_cell_room(visited, prev_cell), room.id])
			)
		prev_cell = cell
		room_count += 1

	_carve_corridors(layout)
	_assign_types(rng, layout)
	_place_monsters(rng, layout)
	return layout


func prev_cell_room(visited: Dictionary, cell: int) -> int:
	return int(visited[cell])


func _shuffle_cells(rng: RandomNumberGenerator, cols: int, rows: int) -> Array:
	var cells: Array = []
	for y in rows:
		for x in cols:
			cells.append(y * cols + x)
	for i in cells.size() - 1:
		var j := rng.randi_range(i, cells.size() - 1)
		var tmp = cells[i]
		cells[i] = cells[j]
		cells[j] = tmp
	return cells


func _make_room_rect(rng: RandomNumberGenerator, cell: int, cols: int) -> Rect2:
	var cx := cell % cols
	var cy := int(cell / cols)
	var origin_x := cx * CELL_TILES
	var origin_y := cy * CELL_TILES
	var margin := 1
	var max_w := CELL_TILES - margin * 2
	var max_h := CELL_TILES - margin * 2
	var w := rng.randi_range(6, max_w)
	var h := rng.randi_range(5, max_h)
	var x := origin_x + margin + rng.randi_range(0, max_w - w)
	var y := origin_y + margin + rng.randi_range(0, max_h - h)
	return Rect2(x, y, w, h)


## Build L-shaped corridor rects between connected room centers.
func _carve_corridors(layout: FloorLayout) -> void:
	layout.corridors.clear()
	for edge in layout.connections:
		var a := layout.room_by_id(edge[0]).center()
		var b := layout.room_by_id(edge[1]).center()
		_add_corridor_segment(layout, a.x, a.y, b.x, a.y)
		_add_corridor_segment(layout, b.x, a.y, b.x, b.y)


func _add_corridor_segment(layout: FloorLayout, x0: int, y0: int, x1: int, y1: int) -> void:
	var x := mini(x0, x1)
	var y := mini(y0, y1)
	var w := absi(x1 - x0) + CORRIDOR_WIDTH
	var h := absi(y1 - y0) + CORRIDOR_WIDTH
	layout.corridors.append(Rect2(x, y, maxi(w, CORRIDOR_WIDTH), maxi(h, CORRIDOR_WIDTH)))


## Mark Entrance (first), Stairs (farthest by BFS), required Balcony/Bedroom, rest from pool.
func _assign_types(rng: RandomNumberGenerator, layout: FloorLayout) -> void:
	layout.entrance_room = layout.rooms[0].id
	var dist := layout.room_distance(layout.entrance_room)
	var farthest := layout.entrance_room
	var far_d := -1
	for id in dist:
		if dist[id] > far_d:
			far_d = dist[id]
			farthest = id
	layout.stairs_room = farthest

	var used: Array[int] = [layout.entrance_room, layout.stairs_room]
	# Balconies: 1-2, never entrance/stairs.
	var balcony_count := rng.randi_range(1, 2)
	for _i in balcony_count:
		var rid := _pick_unused(rng, layout, used)
		if rid != -1:
			layout.room_by_id(rid).type = FloorLayout.TYPE_BALCONY
			used.append(rid)
	# Bedrooms: at least 1.
	var bed := _pick_unused(rng, layout, used)
	if bed != -1:
		layout.room_by_id(bed).type = FloorLayout.TYPE_BEDROOM
		used.append(bed)
	# Remaining rooms get a random pool type.
	for r in layout.rooms:
		if r.id in used:
			continue
		r.type = FloorLayout.ROOM_POOL[rng.randi_range(0, FloorLayout.ROOM_POOL.size() - 1)]


func _pick_unused(rng: RandomNumberGenerator, layout: FloorLayout, used: Array) -> int:
	var candidates: Array[int] = []
	for r in layout.rooms:
		if not (r.id in used):
			candidates.append(r.id)
	if candidates.is_empty():
		return -1
	return candidates[rng.randi_range(0, candidates.size() - 1)]


## Monster spawns (docs/generation.md §4): 3-8, scale with floor, not in entrance/balcony.
func _place_monsters(rng: RandomNumberGenerator, layout: FloorLayout) -> void:
	layout.monster_spawns.clear()
	var count := clampi(3 + layout.floor_index, 3, 8)
	var candidates: Array[int] = []
	for r in layout.rooms:
		if r.id == layout.entrance_room:
			continue
		if r.type == FloorLayout.TYPE_BALCONY:
			continue
		candidates.append(r.id)
	for _ci in candidates.size() - 1:
		var _cj := rng.randi_range(_ci, candidates.size() - 1)
		var _ctmp = candidates[_ci]
		candidates[_ci] = candidates[_cj]
		candidates[_cj] = _ctmp
	for i in mini(count, candidates.size()):
		layout.monster_spawns.append(layout.room_by_id(candidates[i]).center())
	# If too few candidate rooms, pad with jittered positions inside non-entrance rooms.
	var pad := 0
	while layout.monster_spawns.size() < count and pad < 50:
		pad += 1
		var r := layout.rooms[rng.randi_range(0, layout.rooms.size() - 1)]
		if r.id == layout.entrance_room:
			continue
		var c := r.center()
		layout.monster_spawns.append(
			Vector2i(c.x + rng.randi_range(-2, 2), c.y + rng.randi_range(-2, 2))
		)
