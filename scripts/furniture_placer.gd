class_name FurniturePlacer
extends RefCounted
## Places hiding furniture into a generated floor per docs/generation.md §3:
## one Bed per Bedroom room, and 0-2 Wardrobes in corridors / bedroom closets.
## Uses Bed.tscn and Wardrobe.tscn scenes with their own textures.
## Deterministic for a given seed. See docs/roadmap.md M13.

const BED_SCENE := preload("res://scenes/Bed.tscn")
const WARDROBE_SCENE := preload("res://scenes/Wardrobe.tscn")
const WARDROBE_MAX := 2


## Place furniture from `layout` into `container`. `seed` keeps placement reproducible.
## Returns the Array of created Furniture instances.
func place(layout: FloorLayout, container: Node, seed: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var created: Array = []

	# One bed per bedroom, near the room center.
	for rd in layout.rooms:
		if rd.type != FloorLayout.TYPE_BEDROOM:
			continue
		var bed := _spawn(
			FurniturePlacer.BED_SCENE, container, Config.TILE_SIZE * rd.center()
		)
		bed.is_bed = true
		bed.prompt_text = "Rest"
		created.append(bed)

	# 0-2 wardrobes, in corridors if any, else near bedroom closets.
	var wardrobe_count := rng.randi_range(0, WARDROBE_MAX)
	var spots: Array = []
	for cor in layout.corridors:
		spots.append(Config.TILE_SIZE * cor.get_center())
	if spots.is_empty():
		for rd in layout.rooms:
			if rd.type == FloorLayout.TYPE_BEDROOM:
				spots.append(Config.TILE_SIZE * rd.center())
	_seeded_shuffle(spots, rng)
	for i in mini(wardrobe_count, spots.size()):
		var ward := _spawn(FurniturePlacer.WARDROBE_SCENE, container, spots[i])
		ward.is_bed = false
		ward.prompt_text = "Hide"
		created.append(ward)

	return created


func _spawn(scene: PackedScene, container: Node, pos: Vector2) -> Furniture:
	var f := scene.instantiate()
	f.global_position = pos
	container.add_child(f)
	return f


## Pure helper (unit-testable): how many bedrooms a layout has (== expected bed count).
static func bedroom_count(layout: FloorLayout) -> int:
	var n := 0
	for rd in layout.rooms:
		if rd.type == FloorLayout.TYPE_BEDROOM:
			n += 1
	return n


## Deterministic in-place shuffle using the seeded RNG (Array.shuffle uses the
## global RNG and would break the per-seed reproducibility contract).
static func _seeded_shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in arr.size() - 1:
		var j := rng.randi_range(i, arr.size() - 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
