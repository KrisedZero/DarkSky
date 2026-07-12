extends Node
## Item manager (autoload "ItemManager").
## Single entry point for acquiring and consuming items: pickup() adds to InventoryManager,
## use() applies the item's effect (energy/oil/blood-mode/equipment flags) and consumes it.
## Definitions come from data/items.json via ItemDatabase. See docs/roadmap.md M10, docs/items.md.
##
## Behaviors of equipment/rare beyond "owned" (cloak stealth, fire light, night vision, repellent
## pulses, amulet save) are implemented in later milestones (M17/M18/M20); M10 records ownership.

const ITEMS_PATH := "res://data/items.json"

var _db: ItemDatabase = ItemDatabase.new()


func _ready() -> void:
	_db.load_from(ITEMS_PATH)
	if not _db.is_loaded():
		push_error("ItemManager: item database not loaded from %s" % ITEMS_PATH)


## Add `amount` of an item to the inventory (e.g. from a chest or room). Returns success.
func pickup(id: StringName, amount: int = 1) -> bool:
	if not _db.has(id):
		push_warning("ItemManager: unknown item id '%s'" % id)
		return false
	if amount <= 0:
		return false
	InventoryManager.add_item(id, amount)
	return true


## Apply an item's effect to `player` and consume one from the inventory.
## Returns true if the item was used (had an effect).
## `player` may be null for inventory-only effects (e.g. equipment ownership).
func use(id: StringName, player: Node = null) -> bool:
	if ItemsData.is_artifact(id):
		if not InventoryManager.has_artifact(id):
			return false
	elif not InventoryManager.has_item(id, 1):
		return false
	var type := _db.effect_type(id)
	var value := _db.effect_value(id)
	match type:
		"energy":
			if player != null and player.has_method("add_energy"):
				player.add_energy(value)
		"oil":
			if player != null and player.has_method("add_oil"):
				player.add_oil(value)
		"blood_mode":
			InventoryManager.add_artifact(ItemsData.CODEX_BLOOD)
			SignalBus.blood_mode_toggled.emit(true)
		"repel":
			InventoryManager.set_flag(ItemsData.REP_SPRAY, true)
		"shield":
			InventoryManager.set_flag(ItemsData.LIFE_AMULET, true)
		"cloak", "light", "night_vision":
			InventoryManager.set_flag(id, true)
		"danger_sense", "sleep":
			InventoryManager.set_flag(id, true)
		"none", _:
			pass
	InventoryManager.remove_item(id, 1)
	return true


# --- Pure helpers (unit-testable without the autoload) ---


## Resolve an effect type/value pair from a definition dict (used by tests / external tools).
static func resolve_effect(def: Dictionary) -> Dictionary:
	if def.is_empty() or not def.has("effect"):
		return {"type": "none", "value": 0.0}
	var e := def["effect"]
	return {"type": e.get("type", "none"), "value": float(e.get("value", 0))}
