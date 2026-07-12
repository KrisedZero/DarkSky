class_name LootPlacer
extends RefCounted
## Places loot chests into a generated floor per docs/generation.md §5.
## 3-6 chests (>=1 in a bedroom), each with a rolled table: coins by distribution, 40% food,
## 20% oil, ~10% one artifact per floor).
## Reuses Chest (M14) + InventoryManager/ItemManager (M9/M10).
## Deterministic for a given seed. See docs/roadmap.md M14 and docs/generation.md §5.

const CHEST_SCENE := preload("res://scenes/Chest.tscn")
const CHEST_MIN := 3
const CHEST_MAX := 6
const FOOD_CHANCE := 0.4
const OIL_CHANCE := 0.2
const ARTIFACT_CHANCE := 0.1  # exactly one artifact per floor when rolled

# Food rarity weights (apple/cookie common, cheese uncommon, pie rare).
const FOOD_WEIGHTS := {
	ItemsData.APPLE: 40, ItemsData.COOKIE: 40, ItemsData.CHEESE: 15, ItemsData.PIE: 5
}


## Roll one chest's loot. `allow_artifact` gates the Blood Codex;
## the caller ensures at most one artifact per floor. `blood_mode` scales resources
## down by BLOOD_MODE_RESOURCE_FACTOR (~40% rarer, gameplay.md §10).
func roll_loot(rng: RandomNumberGenerator, allow_artifact: bool, blood_mode: bool = false) -> Dictionary:
	var loot: Dictionary = {}
	var factor := 1.0 if not blood_mode else Config.BLOOD_MODE_RESOURCE_FACTOR
	loot[ItemsData.COIN] = _roll_coins(rng, factor)
	if rng.randf() < FOOD_CHANCE * factor:
		loot[_roll_food(rng)] = 1
	if rng.randf() < OIL_CHANCE * factor:
		# Small:large oil ratio is data-driven (BalancingConfig.loot_oil_small_ratio, M27).
		var oil_id := ItemsData.OIL_SMALL if rng.randf() < Config.LOOT_OIL_SMALL_RATIO else ItemsData.OIL_LARGE
		loot[oil_id] = 1
	if allow_artifact:
		loot[ItemsData.CODEX_BLOOD] = 1
	return loot


func _roll_coins(rng: RandomNumberGenerator, factor: float = 1.0) -> int:
	# ~70% 1-5, ~15% 6-9, ~5% 10, remainder 1-10.
	var r := rng.randf()
	if r < 0.70:
		return maxi(1, int(round(rng.randi_range(1, 5) * factor)))
	if r < 0.85:
		return maxi(1, int(round(rng.randi_range(6, 9) * factor)))
	if r < 0.90:
		return maxi(1, int(round(10 * factor)))
	return maxi(1, int(round(rng.randi_range(1, 10) * factor)))


func _roll_food(rng: RandomNumberGenerator) -> StringName:
	var total := 0
	for w in FOOD_WEIGHTS.values():
		total += w
	var pick := rng.randi_range(1, total)
	for id in FOOD_WEIGHTS:
		pick -= int(FOOD_WEIGHTS[id])
		if pick <= 0:
			return id
	return ItemsData.APPLE


## Place chests from `layout` into `container`. `seed` keeps placement reproducible.
## Returns the Array of created Chest instances.
func place(layout: FloorLayout, container: Node, seed: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var bedrooms: Array = []
	var others: Array = []
	for rd in layout.rooms:
		if rd.type == FloorLayout.TYPE_BEDROOM:
			bedrooms.append(rd)
		else:
			others.append(rd)

	var count := rng.randi_range(CHEST_MIN, CHEST_MAX)
	# Always include at least one bedroom (spec: >=1 chest in a bedroom).
	var chosen: Array = []
	if not bedrooms.is_empty():
		chosen.append(bedrooms[rng.randi_range(0, bedrooms.size() - 1)])
	var pool := others.duplicate()
	_seeded_shuffle(pool, rng)
	for r in pool:
		if chosen.size() >= count:
			break
		chosen.append(r)
	# If still short (very small floor), top up from remaining bedrooms.
	var bi := 0
	while chosen.size() < count and bi < bedrooms.size():
		if not (bedrooms[bi] in chosen):
			chosen.append(bedrooms[bi])
		bi += 1

	# At most one artifact per floor, and only if not already owned this run.
	var owned_codex := InventoryManager.has_artifact(ItemsData.CODEX_BLOOD)
	var artifact_for_floor := not owned_codex and rng.randf() < ARTIFACT_CHANCE
	var artifact_index := -1
	if artifact_for_floor and not chosen.is_empty():
		artifact_index = rng.randi_range(0, chosen.size() - 1)

	var created: Array = []
	for i in chosen.size():
		var rd: FloorLayout.RoomData = chosen[i]
		var allow := artifact_for_floor and i == artifact_index
		var loot := roll_loot(rng, allow, owned_codex)
		var chest := CHEST_SCENE.instantiate()
		chest.chest_id = layout.floor_index * 1000 + i + 1
		chest.loot = loot
		chest.global_position = Config.TILE_SIZE * rd.center()
		container.add_child(chest)
		created.append(chest)
	return created


## Pure helper (unit-testable): count bedrooms among chosen rooms for the >=1 rule.
static func has_bedroom_chest(chosen: Array) -> bool:
	for rd in chosen:
		if rd.type == FloorLayout.TYPE_BEDROOM:
			return true
	return false


## Deterministic in-place shuffle using the seeded RNG (Array.shuffle uses the
## global RNG and would break the per-seed reproducibility contract).
static func _seeded_shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in arr.size() - 1:
		var j := rng.randi_range(i, arr.size() - 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
