class_name Merchant
extends BaseInteractable
## Ghost merchant (M18). Appears on floors >= 2 with 50% chance (not entrance/exit room).
## Sells the items tagged "merchant" in data/items.json, restocked deterministically per floor.
## Buying spends coins and grants the item (or unique artifact). Interaction opens the trade UI
## (consumed later by M23/M24) and records the merchant_visited flag. See docs/roadmap.md M18,
## docs/gameplay-summary.md §8, docs/generation.md §6.
##
## Conflict flags: prices are provisional (items.md gives loose ranges vs "5-10" in generation.md);
## Night Vision appears in items.json but lacks a canonical items.md table row (C6).

const MERCHANT_SEED_OFFSET: int = 313

var stock: Array = []  # Array of {id: StringName, price: int}


func _on_ready() -> void:
	_build_stock()


## Build the per-floor stock from the item database (entries whose spawns include "merchant").
## Deterministic: a seeded shuffle of the catalog using the current floor seed. The Blood Codex is
## removed if already owned so the merchant disappears after it is bought (gameplay.md §8).
func _build_stock() -> void:
	stock.clear()
	var db: ItemDatabase = ItemManager._db
	var candidates: Array = []
	for id in db.all_ids():
		var def := db.get_def(id)
		if "merchant" in def.get("spawns", []):
			candidates.append({"id": StringName(id), "price": int(def.get("price", 0))})
	var rng := RandomNumberGenerator.new()
	rng.seed = GameManager.floor_seed(GameManager.current_floor) + MERCHANT_SEED_OFFSET
	_seeded_shuffle(candidates, rng)
	for entry in candidates:
		if ItemsData.is_artifact(entry["id"]) and InventoryManager.has_artifact(entry["id"]):
			continue
		stock.append(entry)


func _seeded_shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in arr.size() - 1:
		var j := rng.randi_range(i, arr.size() - 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


## Price of an item id in this merchant's stock, or -1 if not sold here.
func price_of(id: StringName) -> int:
	for entry in stock:
		if entry["id"] == id:
			return int(entry["price"])
	return -1


## Attempt to buy `id`. Spends coins and grants the item on success. Returns true if purchased.
## Pure-ish: reads/writes InventoryManager; does not depend on the physics loop.
func try_buy(id: StringName) -> bool:
	var price := price_of(id)
	if price < 0:
		return false
	if InventoryManager.coins < price:
		return false
	if ItemsData.is_artifact(id):
		if InventoryManager.has_artifact(id):
			return false
		InventoryManager.add_artifact(id)
		if id == ItemsData.CODEX_BLOOD:
			SignalBus.blood_mode_toggled.emit(true)
	else:
		InventoryManager.add_item(id, 1)
	InventoryManager.spend_coins(price)
	return true


## Interacting opens the trade UI (later milestone) and records that the merchant was visited.
func interact(_interactor: Node) -> void:
	SignalBus.merchant_trade_opened.emit(self)
	InventoryManager.set_flag("merchant_visited", true)
