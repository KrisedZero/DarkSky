class_name FloorLayout
extends RefCounted
## Pure data model for a generated floor (tile coordinates).
## Produced by FloorGenerator; consumed by Rooms (M12), Loot (M14), Doors (M15), Monster AI (M17).
## Saving (M16). Holds no nodes — just geometry + metadata, so generation stays
## deterministic/testable.
## See docs/roadmap.md M11, docs/generation.md.

## Room category tags (docs/generation.md §1).
const TYPE_ENTRANCE := &"ENTRANCE"
const TYPE_STAIRS := &"STAIRS"
const TYPE_BALCONY := &"BALCONY"
const TYPE_BEDROOM := &"BEDROOM"
const TYPE_HALL := &"HALL"
const TYPE_LIBRARY := &"LIBRARY"
const TYPE_KITCHEN := &"KITCHEN"
const TYPE_DINING := &"DINING"
const TYPE_STORAGE := &"STORAGE"
const TYPE_CHAPEL := &"CHAPEL"
const TYPE_SECRET := &"SECRET"

const ROOM_POOL := PackedStringArray(
	[TYPE_HALL, TYPE_LIBRARY, TYPE_KITCHEN, TYPE_DINING, TYPE_STORAGE, TYPE_CHAPEL, TYPE_SECRET]
)


## One room in the layout (tile-space rect + role).
class RoomData:
	var id: int = 0
	var rect: Rect2 = Rect2()
	var type: StringName = FloorLayout.TYPE_HALL

	func center() -> Vector2i:
		return Vector2i(int(rect.get_center().x), int(rect.get_center().y))

	func to_dict() -> Dictionary:
		return {
			"id": id,
			"x": rect.position.x,
			"y": rect.position.y,
			"w": rect.size.x,
			"h": rect.size.y,
			"type": type,
		}

	func _to_string() -> String:
		return "Room#%d %s %s" % [id, type, rect]


var seed: int = 0
var floor_index: int = 0
var rooms: Array[RoomData] = []
var connections: Array[PackedInt32Array] = []  # edges between room ids (tree)
var corridors: Array[Rect2] = []  # L-shaped walkable links (tile rects)
var entrance_room: int = 0
var stairs_room: int = 0
var monster_spawns: Array[Vector2i] = []


func room_by_id(id: int) -> RoomData:
	for r in rooms:
		if r.id == id:
			return r
	return null


## M20: is `tile_pos` inside any balcony room (a monster safe zone per gameplay.md §5)?
func is_balcony_at(tile_pos: Vector2) -> bool:
	for r in rooms:
		if r.type == TYPE_BALCONY and r.rect.has_point(tile_pos):
			return true
	return false


## M29: is `tile_pos` inside the stairs room (the floor-exit / win trigger, ADR-015)?
func is_stairs_at(tile_pos: Vector2) -> bool:
	var r := room_by_id(stairs_room)
	return r != null and r.rect.has_point(tile_pos)


## Tile bounds enclosing every room and corridor.
func bounds() -> Rect2:
	if rooms.is_empty():
		return Rect2()
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF
	for r in rooms:
		min_x = minf(min_x, r.rect.position.x)
		min_y = minf(min_y, r.rect.position.y)
		max_x = maxf(max_x, r.rect.end.x)
		max_y = maxf(max_y, r.rect.end.y)
	for c in corridors:
		min_x = minf(min_x, c.position.x)
		min_y = minf(min_y, c.position.y)
		max_x = maxf(max_x, c.end.x)
		max_y = maxf(max_y, c.end.y)
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


func entrance_pos() -> Vector2i:
	return room_by_id(entrance_room).center()


func stairs_pos() -> Vector2i:
	return room_by_id(stairs_room).center()


## BFS distance (in rooms) from `start` over the connection tree.
func room_distance(start: int) -> Dictionary:
	var dist: Dictionary = {}
	dist[start] = 0
	var queue := [start]
	while not queue.is_empty():
		var cur: int = queue.pop_front()
		for edge in connections:
			var nxt := -1
			if edge[0] == cur:
				nxt = edge[1]
			elif edge[1] == cur:
				nxt = edge[0]
			if nxt == -1 or dist.has(nxt):
				continue
			dist[nxt] = dist[cur] + 1
			queue.append(nxt)
	return dist


## Save schema (M16): enough to rebuild identically from seed, plus resolved rooms for validation.
func to_dict() -> Dictionary:
	var rooms_arr: Array = []
	for r in rooms:
		rooms_arr.append(r.to_dict())
	return {
		"seed": seed,
		"floor_index": floor_index,
		"rooms": rooms_arr,
		"connections": connections,
		"corridors": corridors,
		"entrance_room": entrance_room,
		"stairs_room": stairs_room,
		"monster_spawns": monster_spawns,
	}


func from_dict(data: Dictionary) -> void:
	seed = int(data.get("seed", 0))
	floor_index = int(data.get("floor_index", 0))
	rooms.clear()
	for rd in data.get("rooms", []):
		var r := RoomData.new()
		r.id = int(rd["id"])
		r.rect = Rect2(float(rd["x"]), float(rd["y"]), float(rd["w"]), float(rd["h"]))
		r.type = StringName(rd["type"])
		rooms.append(r)
	connections = data.get("connections", [])
	corridors = data.get("corridors", [])
	entrance_room = int(data.get("entrance_room", 0))
	stairs_room = int(data.get("stairs_room", 0))
	monster_spawns = data.get("monster_spawns", [])
