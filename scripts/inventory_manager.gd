extends Node
## Inventory manager (autoload "InventoryManager").
## Holds run state for coins, stackable items (keys, food, fuel, rare) and unique artifacts.
## Pure-ish data API with signals; effects are applied elsewhere (Items M10, Player, etc.).
## See docs/roadmap.md M9, docs/architecture.md (Inventory System), docs/items.md.
##
## Persistence note: this is the single source of truth that Saving (M16) serializes.

var coins: int = 0
var artifacts: Array[StringName] = []
var flags: Dictionary = {}  # StringName -> bool/int (equipment/rare ownership)
var _stacks: Dictionary = {}  # StringName -> int

# --- Coins ---


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	_add_stack(ItemsData.COIN, amount)
	coins = _stacks.get(ItemsData.COIN, 0)
	SignalBus.coins_changed.emit(coins)
	SignalBus.inventory_changed.emit()


## Returns true and deducts on success; false if insufficient.
func spend_coins(amount: int) -> bool:
	if amount <= 0:
		return true
	if coins < amount:
		return false
	_add_stack(ItemsData.COIN, -amount)
	coins = _stacks.get(ItemsData.COIN, 0)
	SignalBus.coins_changed.emit(coins)
	SignalBus.inventory_changed.emit()
	return true


# --- Stackable items ---


func add_item(id: StringName, amount: int = 1) -> void:
	if amount <= 0:
		return
	if not ItemsData.is_stackable(id):
		push_warning("InventoryManager: '%s' is not a stackable item" % id)
		return
	_add_stack(id, amount)
	SignalBus.inventory_changed.emit()


func remove_item(id: StringName, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if count(id) < amount:
		return false
	_add_stack(id, -amount)
	SignalBus.inventory_changed.emit()
	return true


func count(id: StringName) -> int:
	return int(_stacks.get(id, 0))


func has_item(id: StringName, amount: int = 1) -> bool:
	return count(id) >= amount


# --- Artifacts (unique) ---


func add_artifact(id: StringName) -> bool:
	if not ItemsData.is_artifact(id):
		push_warning("InventoryManager: '%s' is not an artifact" % id)
		return false
	if id in artifacts:
		return false
	artifacts.append(id)
	SignalBus.artifact_acquired.emit(id)
	SignalBus.inventory_changed.emit()
	return true


func has_artifact(id: StringName) -> bool:
	return id in artifacts


func remove_artifact(id: StringName) -> void:
	if artifacts.has(id):
		artifacts.erase(id)
		SignalBus.inventory_changed.emit()


# --- Equipment / rare flags (ownership of unique items) ---


func set_flag(id: StringName, value: bool) -> void:
	flags[id] = value
	SignalBus.inventory_changed.emit()


func get_flag(id: StringName) -> bool:
	return bool(flags.get(id, false))


func has_flag(id: StringName) -> bool:
	return get_flag(id)


# --- Lifecycle ---


## Reset all run state (new game / restart).
func clear() -> void:
	coins = 0
	_stacks.clear()
	artifacts.clear()
	flags.clear()
	SignalBus.coins_changed.emit(0)
	SignalBus.inventory_changed.emit()


## Snapshot run state for saving (M16). Returns plain serializable data.
func get_save_data() -> Dictionary:
	return {
		"coins": coins,
		"stacks": _stacks.duplicate(),
		"artifacts": artifacts.duplicate(),
		"flags": flags.duplicate(),
	}


## Restore run state from a snapshot produced by get_save_data() (M16).
func load_save_data(data: Dictionary) -> void:
	clear()
	coins = int(data.get("coins", 0))
	var stacks := {}
	for k in data.get("stacks", {}):
		stacks[StringName(k)] = int(data["stacks"][k])
	_stacks = stacks
	var arts: Array[StringName] = []
	for a in data.get("artifacts", []):
		arts.append(StringName(a))
	artifacts = arts
	var fl := {}
	for k in data.get("flags", {}):
		fl[StringName(k)] = data["flags"][k]
	flags = fl
	SignalBus.coins_changed.emit(coins)
	SignalBus.inventory_changed.emit()


func _add_stack(id: StringName, delta: int) -> void:
	var next := int(_stacks.get(id, 0)) + delta
	if next <= 0:
		_stacks.erase(id)
	else:
		_stacks[id] = next


# --- Pure helpers (unit-testable without the autoload) ---


## Pure merge of a stack delta into a copy of the stacks dict; returns the new dict.
static func apply_delta(stacks: Dictionary, id: StringName, delta: int) -> Dictionary:
	var next := stacks.duplicate()
	var v := int(next.get(id, 0)) + delta
	if v <= 0:
		next.erase(id)
	else:
		next[id] = v
	return next


## Pure check that a list of required stack counts is satisfied by `stacks`.
static func can_afford(stacks: Dictionary, coins: int, price: int, required: Dictionary) -> bool:
	if coins < price:
		return false
	for id in required:
		if int(stacks.get(id, 0)) < int(required[id]):
			return false
	return true


# --- Lifecycle / internal ---


func _ready() -> void:
	SignalBus.inventory_changed.connect(_on_inventory_changed)


func _on_inventory_changed() -> void:
	# Keep the dedicated coin signal in sync if a system mutates stacks directly.
	if coins != _stacks.get(ItemsData.COIN, 0):
		coins = _stacks.get(ItemsData.COIN, 0)
		SignalBus.coins_changed.emit(coins)
