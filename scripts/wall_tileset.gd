class_name WallTileset
extends RefCounted
## Visual TileSet for world walls (M30). A single 32x32 wall texture; collision is handled
## separately by FloorBuilder via a static collision body, so this TileSet carries no physics.
## See docs/roadmap.md M30.

static var WALL_TEX: Texture2D = load("res://assets/tilesets/wall_stone.png")


static func build() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	var src := TileSetAtlasSource.new()
	src.texture = WALL_TEX
	src.texture_region_size = Vector2i(32, 32)
	src.margins = Vector2i(0, 0)
	src.separation = Vector2i(0, 0)
	src.create_tile(Vector2i(0, 0))
	ts.add_source(src, 0)
	return ts
