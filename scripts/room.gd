class_name Room
extends Node2D
## One instantiated room, built from a FloorLayout.RoomData by FloorBuilder.
## Uses a TileMapLayer to paint floor tiles (32×32), placed by room type.
## Furniture/chest/monster anchors are added later (M13/M14/M17).
## The Room node is positioned at the room's top-left in pixels by the builder.

var data: FloorLayout.RoomData

@onready var _tilemap: TileMapLayer = $TileMapLayer
@onready var _center: Marker2D = $Center


func _ready() -> void:
	if not has_node("TileMapLayer"):
		var tml := TileMapLayer.new()
		tml.name = "TileMapLayer"
		add_child(tml)
		_tilemap = tml
	if not has_node("Center"):
		var m := Marker2D.new()
		m.name = "Center"
		add_child(m)
		_center = m


func setup(d: FloorLayout.RoomData, tileset: TileSet = _tilemap.tile_set) -> void:
	data = d
	_tilemap.tile_set = tileset

	var w := int(d.rect.size.x)
	var h := int(d.rect.size.y)
	var src_id := FloorTileset.tile_for_room(d.type)

	for y in h:
		for x in w:
			_tilemap.set_cell(Vector2i(x, y), src_id, Vector2i(0, 0))

	_center.position = Config.TILE_SIZE * d.rect.size * 0.5


func center_global() -> Vector2:
	return _center.global_position


func room_type() -> StringName:
	return data.type
