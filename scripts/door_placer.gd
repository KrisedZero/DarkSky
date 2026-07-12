class_name DoorPlacer
extends RefCounted
## Places doors on corridor segments and matching keys per docs/generation.md §2.
## Some doors are locked (require a KEY); locked doors are capped at 3 per floor. Each locked door's
## key is placed on the entrance side so the floor stays completable. Reuses Door/KeyItem (M15).
## See docs/roadmap.md M15.
## Deterministic for a given seed. See docs/roadmap.md M15.

const DOOR_SCENE := preload("res://scenes/Door.tscn")
const KEY_SCENE := preload("res://scenes/KeyItem.tscn")
const LOCKED_MAX := 3


## Place doors + keys from `layout` into `container`. `seed` keeps placement reproducible.
## `world_grid` (M30) lets closed doors block movement + monster pathfinding; pass null otherwise.
## Returns a dict { "doors": Array[Door], "keys": Array[KeyItem], "locked": int }.
func place(layout: FloorLayout, container: Node, seed: int, world_grid: WorldGrid = null) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var corridor_count := layout.corridors.size()
	var door_count := 0
	if corridor_count > 0:
		door_count = clampi(rng.randi_range(3, 6), 0, corridor_count)
	var indices: Array = range(corridor_count)
	_seeded_shuffle(indices, rng)
	indices = indices.slice(0, door_count)

	var locked_count := 0
	if door_count > 0:
		locked_count = mini(LOCKED_MAX, rng.randi_range(0, mini(LOCKED_MAX, door_count)))
	var locked_set: Dictionary = {}
	var locked_indices: Array = indices.duplicate()
	_seeded_shuffle(locked_indices, rng)
	for i in mini(locked_count, locked_indices.size()):
		locked_set[locked_indices[i]] = true

	var doors: Array = []
	for idx in indices:
		var cor := layout.corridors[idx]
		var door := DOOR_SCENE.instantiate()
		door.door_id = layout.floor_index * 1000 + idx + 1
		door.is_locked = locked_set.has(idx)
		door.global_position = Config.TILE_SIZE * cor.get_center()
		container.add_child(door)
		door.world_grid = world_grid
		doors.append(door)

	# One key per locked door, on the entrance side of that door's edge.
	var keys: Array = []
	var key_room_pool: Array = []
	for idx in indices:
		if not locked_set.has(idx):
			continue
		var edge: PackedInt32Array = layout.connections[idx]
		var side := entrance_side_rooms(layout, edge[0], edge[1])
		if key_room_pool.is_empty():
			key_room_pool = side.duplicate()
			_seeded_shuffle(key_room_pool, rng)
		var room_id := key_room_pool.pop_front() if not key_room_pool.is_empty() else edge[0]
		var rd := layout.room_by_id(room_id)
		var key := KEY_SCENE.instantiate()
		key.key_id = layout.floor_index * 1000 + idx + 1
		key.global_position = Config.TILE_SIZE * rd.center()
		container.add_child(key)
		keys.append(key)

	return {"doors": doors, "keys": keys, "locked": locked_count}


## Deterministic in-place shuffle using the seeded RNG (Array.shuffle uses the
## global RNG and would break the per-seed reproducibility contract).
static func _seeded_shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in arr.size() - 1:
		var j := rng.randi_range(i, arr.size() - 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


## Rooms reachable from the entrance side of edge (a,b) without crossing that edge
## (the layout is a tree, so a door edge splits it into two sides).
static func entrance_side_rooms(layout: FloorLayout, a: int, b: int) -> Array:
	var dist := layout.room_distance(layout.entrance_room)
	var from_id := a if dist.get(a, 9999) <= dist.get(b, 9999) else b
	var seen: Dictionary = {}
	var queue := [from_id]
	seen[from_id] = true
	while not queue.is_empty():
		var cur: int = queue.pop_front()
		for edge in layout.connections:
			if edge.has(cur):
				var nxt := edge[0] if edge[1] == cur else edge[1]
				# Skip the door edge itself.
				if (edge[0] == a and edge[1] == b) or (edge[0] == b and edge[1] == a):
					continue
				if not seen.has(nxt):
					seen[nxt] = true
					queue.append(nxt)
	return seen.keys()
