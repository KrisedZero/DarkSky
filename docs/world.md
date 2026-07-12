# docs/world.md

# Room Node Contract

This document defines the Room node contract — the expected node paths and interface for a `Room` instance built from a `FloorLayout.RoomData`. Every downstream system (Furniture, Loot, Doors, Monster AI, Merchant) places its content relative to this contract.

## Room Node Structure

```
Room (Node2D)               ← positioned at top-left corner in pixels
├── Floor (Polygon2D)       ← type-tinted rect, sized from RoomData.rect * TILE_SIZE
├── Center (Marker2D)       ← center of the room (size_px * 0.5 in local space)
└── <child nodes>           ← furniture, chests, doors, monsters, merchant (added by placers)
```

## FloorBuilder Output

`FloorBuilder.build(layout, container)` returns a Dictionary:
- `"rooms": Array[Room]` — one per layout room
- `"corridors": Array[Polygon2D]` — L-shaped walkable strips
- `"bounds_px": Rect2` — pixel-space bounding rectangle of the entire floor
- `"entrance_px": Vector2` — player spawn position (entrance room center in pixels)

## Room API (room.gd)

| Method | Returns | Description |
|--------|---------|-------------|
| `setup(data: RoomData)` | void | Initialize geometry from layout data |
| `center_global()` | Vector2 | Global position of the room center |
| `room_type()` | StringName | Room type tag (e.g. `TYPE_BALCONY`) |
| `color_for(type)` | Color | Static: deterministic tint per room type |

## Placement System Contract

All placers (FurniturePlacer, LootPlacer, DoorPlacer, MonsterPlacer, MerchantPlacer) follow the same pattern:
1. Accept `layout: FloorLayout`, `container: Node`, `seed: int`
2. Place items as children of `container`
3. Use `Config.TILE_SIZE * layout.room_by_id(id).center()` for positioning
4. Output is deterministic for a given seed

## Save/Restore Contract

- `FloorLayout.to_dict() / from_dict()` provides complete serialization
- `SaveManager.apply_opened_to_scene(root)` marks chests/doors as opened after load
- Restore timeline: regenerate floor from seed → build rooms → apply opened IDs → spawn player
