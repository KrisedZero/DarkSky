class_name MerchantPlacer
extends RefCounted
## Places the ghost merchant (M18) with 50% chance on floors >= 2, in a random room that is
## neither the entrance nor the stairs (docs/generation.md §6, docs/gameplay-summary.md §8).
## Deterministic via the floor seed; the merchant is an interactable (opens trade later). See M18.
## Conflict: generation.md says prices "5-10" while items.md gives per-item ranges (C?); prices live
## in data/items.json and are provisional.

const MERCHANT_SCENE := preload("res://scenes/Merchant.tscn")
const SPAWN_CHANCE: float = 0.5


## Returns an array with 0 or 1 Merchant (at most one per floor, per design).
func place(layout: FloorLayout, container: Node, seed: int) -> Array:
	var out: Array = []
	# Floor 1 (floor_index 0) never has a merchant.
	if layout.floor_index < 1:
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	if rng.randf() >= SPAWN_CHANCE:
		return out
	var candidates: Array[int] = []
	for r in layout.rooms:
		if r.id == layout.entrance_room or r.id == layout.stairs_room:
			continue
		candidates.append(r.id)
	if candidates.is_empty():
		return out
	var rid := candidates[rng.randi_range(0, candidates.size() - 1)]
	var room := layout.room_by_id(rid)
	var m: Merchant = MERCHANT_SCENE.instantiate()
	m.global_position = Config.TILE_SIZE * Vector2(room.center().x, room.center().y)
	container.add_child(m)
	out.append(m)
	return out
