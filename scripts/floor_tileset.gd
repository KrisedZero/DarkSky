class_name FloorTileset
extends RefCounted
## Builds a TileSet for floor rendering at runtime. Exposes tile IDs indexed by the
## FloorLayout room type constants so Room can paint tiles without switch statements.

const TEX_WOOD: int = 0
const TEX_STONE: int = 1
const TEX_CORRIDOR: int = 2
const TEX_BALCONY: int = 3
const TEX_WALL: int = 4
const TEX_WALL_DARK: int = 5


## Build a TileSet with one 32x32 tile per floor type.
static func build() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)

	_add_source(ts, load("res://assets/tilesets/floor_wood.png"))
	_add_source(ts, load("res://assets/tilesets/floor_stone.png"))
	_add_source(ts, load("res://assets/tilesets/floor_corridor.png"))
	_add_source(ts, load("res://assets/tilesets/balcony_floor.png"))
	_add_source(ts, load("res://assets/tilesets/wall_stone.png"))
	_add_source(ts, load("res://assets/tilesets/wall_stone_dark.png"))

	return ts


static func _add_source(ts: TileSet, tex: Texture2D) -> void:
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(32, 32)
	src.margins = Vector2i(0, 0)
	src.separation = Vector2i(0, 0)
	src.create_tile(Vector2i(0, 0))
	ts.add_source(src, ts.get_next_source_id())


## Map room type to tile texture source ID (first source is TEX_WOOD).
static func tile_for_room(type: StringName) -> int:
	match type:
		FloorLayout.TYPE_ENTRANCE:
			return TEX_STONE
		FloorLayout.TYPE_STAIRS:
			return TEX_STONE
		FloorLayout.TYPE_BALCONY:
			return TEX_BALCONY
		FloorLayout.TYPE_BEDROOM:
			return TEX_WOOD
		FloorLayout.TYPE_LIBRARY:
			return TEX_WOOD
		FloorLayout.TYPE_KITCHEN:
			return TEX_STONE
		FloorLayout.TYPE_DINING:
			return TEX_WOOD
		FloorLayout.TYPE_STORAGE:
			return TEX_STONE
		FloorLayout.TYPE_CHAPEL:
			return TEX_WALL_DARK
		FloorLayout.TYPE_SECRET:
			return TEX_WALL_DARK
	return TEX_STONE
