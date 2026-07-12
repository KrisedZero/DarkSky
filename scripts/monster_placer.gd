class_name MonsterPlacer
extends RefCounted
## Places Monster instances on the floor from layout.monster_spawns (M17).
## Spawn tiles come from the seed (FloorGenerator), so placement is deterministic and not saved;
## monsters roam at runtime. See docs/roadmap.md M17, docs/generation.md §4.

const MONSTER_SCENE := preload("res://scenes/Monster.tscn")

## Instantiate one Monster per spawn tile. Returns the spawned Monster array.
## `world_grid` (M30) lets monsters pathfind through corridors; pass null for non-gameplay use.
func place(layout: FloorLayout, container: Node, _seed: int, world_grid: WorldGrid = null) -> Array:
	var out: Array = []
	for spawn in layout.monster_spawns:
		var m: Monster = MONSTER_SCENE.instantiate()
		m.global_position = Config.TILE_SIZE * Vector2(spawn.x, spawn.y)
		m.world_grid = world_grid
		container.add_child(m)
		out.append(m)
	return out
