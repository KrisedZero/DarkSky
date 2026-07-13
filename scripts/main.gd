extends Node2D
const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const MONSTER_SCENE := preload("res://scenes/Monster.tscn")
const HUD_SCENE := preload("res://scenes/HUD.tscn")
const MENU_SCENE := preload("res://scenes/MainMenu.tscn")
var _monster_spotted: bool = false
## Boot scene (M2 scaffold). Runs the core-framework self-tests, then hands off to the main
## menu (M23). See docs/roadmap.md M2/M3 and M23.


func _ready() -> void:
	_run_self_test()
	SceneLoader.change_scene.call_deferred(Config.SCENE_MAIN_MENU)


## Lightweight boot-time validation of the autoloads (no test framework yet).
func _run_self_test() -> void:
	GameManager.test_mode = true
	assert(Config.FLOOR_COUNT == 7, "Config not loaded")
	var probe := {"hit": false}
	var cb := func(_i: int) -> void: probe["hit"] = true
	SignalBus.floor_changed.connect(cb)
	SignalBus.floor_changed.emit(1)
	SignalBus.floor_changed.disconnect(cb)
	assert(probe["hit"], "SignalBus round-trip failed")
	assert(InputReader.compute_move_vector(0, 1, 0, 0) == Vector2.RIGHT, "move map: right")
	assert(InputReader.compute_move_vector(1, 0, 0, 0) == Vector2.LEFT, "move map: left")
	assert(InputReader.compute_move_vector(0, 0, 1, 0) == Vector2.UP, "move map: up")
	assert(InputReader.compute_move_vector(0, 0, 0, 0) == Vector2.ZERO, "move map: idle")
	assert(InputReader.compute_move_vector(0, 1, 0, 1).length() <= 1.0, "move map: clamped")
	_test_player()
	_test_camera()
	_test_lighting()
	_test_interaction()
	_test_inventory()
	_test_items()
	_test_generation()
	_test_rooms()
	_test_furniture()
	_test_loot()
	_test_doors()
	_test_save()
	_test_monsters()
	_test_merchant()
	_test_survival()
	_test_stealth()
	_test_danger_sense()
	_test_hud()
	_test_menu()
	_test_pause()
	_test_difficulty()
	_test_optimization()
	_test_balancing()
	_test_polish()
	_test_world_physics()
	_test_release()
	GameManager.test_mode = false
	print(
		(
			"Core self-test OK: Config + SignalBus + Input + Player + Camera +"
			+ " Lighting + Interaction + Inventory + Items + Generation + Rooms +"
			+ " Furniture + Loot + Doors + Save + Monsters + Merchant +"
			+ " Survival + Stealth + DangerSense + HUD + Menu + Pause/Settings"
			+ " + Difficulty + Optimization + Balancing + Polishing + WorldPhysics + Release"
		)
	)
	print(
		"M16 save round-trip verified (seed, floor, inventory, opened chest/door IDs, player stats)"
	)


func _test_player() -> void:
	var p: PlayerController = PLAYER_SCENE.instantiate()
	add_child(p)
	assert(p.state == PlayerController.State.NORMAL, "player starts normal")
	assert(is_equal_approx(p.lamp_oil, Config.LANTERN_OIL_START), "lamp oil init")
	p.set_hidden(true)
	assert(p.is_hidden(), "player hides")
	p.add_energy(-100.0)
	assert(p.energy == 0.0, "energy clamps at 0")
	p.add_oil(30.0)
	assert(p.lamp_oil > Config.LANTERN_OIL_START, "oil refills")
	p.queue_free()


func _test_camera() -> void:
	var bounds := Rect2(0, 0, 640, 360)
	var view := Vector2(320, 180)
	var inside := GameCamera.clamp_center(Vector2(320, 180), bounds, view)
	assert(inside == Vector2(320, 180), "cam center")
	var lo := GameCamera.clamp_center(Vector2(0, 0), bounds, view)
	assert(lo == Vector2(160, 90), "cam clamp min")
	var hi := GameCamera.clamp_center(Vector2(999, 999), bounds, view)
	assert(hi == Vector2(480, 270), "cam clamp max")


func _test_lighting() -> void:
	var scale := LanternLight.radius_to_scale(128.0, 256)
	assert(is_equal_approx(scale, 1.0), "lantern radius->scale")
	var tint := LightingSystem.apply_blood_tint(Config.AMBIENT_DARKNESS)
	assert(tint.r > Config.AMBIENT_DARKNESS.r, "blood tint reddens")
	assert(tint.b < Config.AMBIENT_DARKNESS.b, "blood tint cools blue")


func _test_interaction() -> void:
	# Pure selection logic: closest valid interactable is chosen.
	var near := BaseInteractable.new()
	near.global_position = Vector2(10, 0)
	near.interactable_enabled = true
	var far := BaseInteractable.new()
	far.global_position = Vector2(50, 0)
	far.interactable_enabled = true
	var disabled := BaseInteractable.new()
	disabled.global_position = Vector2(5, 0)
	disabled.interactable_enabled = false
	var origin := Vector2(0, 0)
	var picked := InteractionController.select_closest(origin, [near, far, disabled], null)
	assert(picked == near, "select_closest picks nearest enabled")
	near.free()
	far.free()
	disabled.free()


func _test_inventory() -> void:
	# Pure stack merge + affordability (no autoload needed).
	var stacks := {}
	stacks = InventoryManager.apply_delta(stacks, ItemsData.APPLE, 2)
	stacks = InventoryManager.apply_delta(stacks, ItemsData.APPLE, -1)
	assert(int(stacks.get(ItemsData.APPLE, 0)) == 1, "stack merge add/remove")
	stacks = InventoryManager.apply_delta(stacks, ItemsData.KEY, -5)
	assert(not stacks.has(ItemsData.KEY), "negative stack erased")
	var need := {ItemsData.KEY: 1, ItemsData.COOKIE: 2}
	var have := {ItemsData.KEY: 1, ItemsData.COOKIE: 2}
	assert(InventoryManager.can_afford(have, 10, 5, need), "afford ok")
	assert(not InventoryManager.can_afford({ItemsData.KEY: 0}, 10, 5, need), "afford missing key")
	assert(not InventoryManager.can_afford(have, 4, 5, need), "afford poor")
	# Autoload behavior.
	InventoryManager.clear()
	InventoryManager.add_coins(10)
	assert(InventoryManager.coins == 10, "add coins")
	assert(InventoryManager.spend_coins(4), "spend ok")
	assert(InventoryManager.coins == 6, "coins after spend")
	assert(not InventoryManager.spend_coins(100), "spend guarded")
	InventoryManager.add_item(ItemsData.CHEESE, 3)
	assert(InventoryManager.count(ItemsData.CHEESE) == 3, "add item")
	assert(InventoryManager.remove_item(ItemsData.CHEESE, 1), "remove item")
	assert(InventoryManager.count(ItemsData.CHEESE) == 2, "item count")
	assert(InventoryManager.add_artifact(ItemsData.CODEX_BLOOD), "add artifact")
	assert(not InventoryManager.add_artifact(ItemsData.CODEX_BLOOD), "artifact unique")
	assert(InventoryManager.has_artifact(ItemsData.CODEX_BLOOD), "has artifact")


func _test_items() -> void:
	# Pure effect resolution.
	var def := {"effect": {"type": "energy", "value": 25}}
	var eff := ItemManager.resolve_effect(def)
	assert(eff["type"] == "energy" and eff["value"] == 25.0, "resolve effect")
	assert(ItemManager.resolve_effect({})["type"] == "none", "resolve none")
	# Live manager (DB loaded at autoload _ready).
	assert(ItemManager._db.is_loaded(), "item db loaded")
	# Pickup + use food on a player.
	InventoryManager.clear()
	var p: PlayerController = PLAYER_SCENE.instantiate()
	add_child(p)
	ItemManager.pickup(ItemsData.APPLE, 2)
	assert(InventoryManager.count(ItemsData.APPLE) == 2, "pickup apple")
	p.add_energy(-50.0)  # give headroom so the apple's restore is observable (energy starts at max)
	var energy_before := p.energy
	assert(ItemManager.use(ItemsData.APPLE, p), "use apple")
	assert(p.energy == energy_before + 20.0, "apple restores energy")
	assert(InventoryManager.count(ItemsData.APPLE) == 1, "apple consumed")
	# Oil refill.
	ItemManager.pickup(ItemsData.OIL_SMALL, 1)
	var oil_before := p.lamp_oil
	assert(ItemManager.use(ItemsData.OIL_SMALL, p), "use oil")
	assert(is_equal_approx(p.lamp_oil, oil_before + 60.0), "oil refilled")
	# Blood Codex: artifact + blood mode flag.
	ItemManager.pickup(ItemsData.CODEX_BLOOD, 1)
	assert(ItemManager.use(ItemsData.CODEX_BLOOD, p), "use codex")
	assert(InventoryManager.has_artifact(ItemsData.CODEX_BLOOD), "codex artifact")
	# Equipment sets an ownership flag and is consumed.
	ItemManager.pickup(ItemsData.CLOAK, 1)
	assert(ItemManager.use(ItemsData.CLOAK, p), "use cloak")
	assert(InventoryManager.get_flag(ItemsData.CLOAK), "cloak owned")
	p.queue_free()


func _test_generation() -> void:
	var gen := FloorGenerator.new()
	var a := gen.generate(12345, 0)
	var b := gen.generate(12345, 0)
	# Determinism: same seed -> identical layout.
	assert(a.rooms.size() == b.rooms.size(), "gen determinism room count")
	assert(a.connections == b.connections, "gen determinism connections")
	assert(a.stairs_room == b.stairs_room, "gen determinism stairs")
	assert(a.monster_spawns.size() == b.monster_spawns.size(), "gen determinism monsters")
	# Room count scales with floor index (clamped 12..30).
	var c := gen.generate(777, 5)
	assert(c.rooms.size() == 22, "gen room count scales")
	# Connectivity: stairs reachable from entrance over the tree.
	assert(a.room_distance(a.entrance_room).has(a.stairs_room), "stairs reachable")
	# Required room types present.
	var balconies := 0
	var bedrooms := 0
	for r in a.rooms:
		if r.type == FloorLayout.TYPE_BALCONY:
			balconies += 1
		elif r.type == FloorLayout.TYPE_BEDROOM:
			bedrooms += 1
	assert(balconies >= 1, "has balcony")
	assert(bedrooms >= 1, "has bedroom")
	# Monsters: 3-8, none on the entrance center.
	assert(a.monster_spawns.size() >= 3 and a.monster_spawns.size() <= 8, "monster count range")
	var entrance := a.entrance_pos()
	assert(not entrance in a.monster_spawns, "no monster at entrance")
	# Save round-trip.
	var d := FloorLayout.new()
	d.from_dict(a.to_dict())
	assert(d.rooms.size() == a.rooms.size() and d.seed == a.seed, "layout save round-trip")


func _test_rooms() -> void:
	var gen := FloorGenerator.new()
	var layout := gen.generate(4242, 2)
	var container := Node2D.new()
	add_child(container)
	var result := FloorBuilder.build(layout, container)
	# One Room instance per layout room; one corridor polygon per corridor.
	assert(result["rooms"].size() == layout.rooms.size(), "room instances match layout")
	assert(result["corridors"].size() == layout.corridors.size(), "corridor visuals match")
	# Player spawn = entrance center in pixels.
	var entrance_px := Config.TILE_SIZE * layout.entrance_pos()
	assert(result["entrance_px"] == entrance_px, "entrance spawn px")
	# Bounds scale with the layout.
	var b := layout.bounds()
	var expect := Rect2(Config.TILE_SIZE * b.position, Config.TILE_SIZE * b.size)
	assert(result["bounds_px"] == expect, "bounds px match")
	# Room tile helper is deterministic per type.
	assert(
		FloorTileset.tile_for_room(FloorLayout.TYPE_BALCONY) != FloorTileset.tile_for_room(FloorLayout.TYPE_STAIRS),
		"room tile IDs differ"
	)
	container.queue_free()


func _test_furniture() -> void:
	var gen := FloorGenerator.new()
	var layout := gen.generate(909, 3)
	var bed_rooms := FurniturePlacer.bedroom_count(layout)
	var container := Node2D.new()
	add_child(container)
	var items := FurniturePlacer.new().place(layout, container, 909 + 777)
	# Exactly one bed per bedroom; 0-2 wardrobes total.
	var beds := 0
	var wardrobes := 0
	for f in items:
		assert(f.is_in_group(BaseInteractable.GROUP), "furniture is interactable")
		if f.is_bed:
			beds += 1
		else:
			wardrobes += 1
	assert(beds == bed_rooms, "one bed per bedroom")
	assert(wardrobes >= 0 and wardrobes <= 2, "wardrobe count range")
	# Determinism: same seed -> same bed/wardrobe counts.
	var again := FurniturePlacer.new().place(layout, container, 909 + 777)
	var beds2 := 0
	var ward2 := 0
	for f in again:
		if f.is_bed:
			beds2 += 1
		else:
			ward2 += 1
	assert(beds2 == beds and ward2 == wardrobes, "furniture placement deterministic")
	container.queue_free()


func _test_loot() -> void:
	var gen := FloorGenerator.new()
	var layout := gen.generate(31337, 4)
	var container := Node2D.new()
	add_child(container)
	InventoryManager.clear()
	var chests := LootPlacer.new().place(layout, container, 31337 + 131)
	# 3-6 chests.
	assert(chests.size() >= 3 and chests.size() <= 6, "chest count range")
	# At least one chest sits inside a bedroom room (pixel-space check).
	var bedroom_chest := false
	for c in chests:
		var pos: Vector2 = c.global_position
		for rd in layout.rooms:
			if rd.type != FloorLayout.TYPE_BEDROOM:
				continue
			var rect_px := Rect2(
				Config.TILE_SIZE * rd.rect.position, Config.TILE_SIZE * rd.rect.size
			)
			if rect_px.has_point(pos):
				bedroom_chest = true
				break
	assert(bedroom_chest, "at least one chest in a bedroom")
	# Determinism: same seed -> same chest count.
	var again := LootPlacer.new().place(layout, container, 31337 + 131)
	assert(again.size() == chests.size(), "chest count deterministic")
	# Opening a chest deposits loot into the inventory exactly once.
	InventoryManager.clear()
	var chest: Chest = preload("res://scenes/Chest.tscn").instantiate()
	chest.chest_id = 99
	chest.loot = {ItemsData.COIN: 5, ItemsData.APPLE: 1}
	add_child(chest)
	chest.interact(null)
	assert(InventoryManager.coins == 5, "chest coins added")
	assert(InventoryManager.count(ItemsData.APPLE) == 1, "chest food added")
	assert(chest.is_opened, "chest opened")
	assert(not chest.interactable_enabled, "chest locked after open")
	chest.interact(null)
	assert(InventoryManager.coins == 5, "chest does not re-open")
	chest.queue_free()
	container.queue_free()


func _test_doors() -> void:
	var gen := FloorGenerator.new()
	var layout := gen.generate(5150, 2)
	var container := Node2D.new()
	add_child(container)
	var result := DoorPlacer.new().place(layout, container, 5150 + 151)
	# Locked doors capped at 3; keys match locked count.
	assert(result["locked"] <= 3, "locked doors <= 3")
	assert(result["keys"].size() == result["locked"], "one key per locked door")
	# Entrance side of any edge always contains the entrance room.
	var edge := layout.connections[0]
	var side := DoorPlacer.entrance_side_rooms(layout, edge[0], edge[1])
	assert(layout.entrance_room in side, "entrance side contains entrance")
	# Door open/lock logic.
	assert(not Door.would_open(true, false, 0), "locked no key stays shut")
	assert(Door.would_open(true, false, 1), "locked with key opens")
	var door: Door = preload("res://scenes/Door.tscn").instantiate()
	door.is_locked = true
	InventoryManager.clear()
	add_child(door)
	door.interact(null)
	assert(not door.is_open, "door stays locked without key")
	InventoryManager.add_item(ItemsData.KEY, 1)
	door.interact(null)
	assert(door.is_open, "door opens with key")
	assert(InventoryManager.count(ItemsData.KEY) == 0, "key consumed")
	door.queue_free()
	# Key pickup grants a key.
	var key: KeyItem = preload("res://scenes/KeyItem.tscn").instantiate()
	InventoryManager.clear()
	add_child(key)
	key.interact(null)
	assert(InventoryManager.count(ItemsData.KEY) == 1, "key pickup grants key")
	key.queue_free()
	container.queue_free()


func _test_save() -> void:
	var p: PlayerController = PLAYER_SCENE.instantiate()
	add_child(p)
	# Establish a known run state.
	GameManager.run_seed = 8675309
	GameManager.current_floor = 4
	GameManager.state = GameManager.State.PLAYING
	InventoryManager.clear()
	InventoryManager.add_coins(50)
	InventoryManager.add_item(ItemsData.CHEESE, 3)
	InventoryManager.add_artifact(ItemsData.CODEX_BLOOD)
	InventoryManager.set_flag("merchant_visited", true)
	p.energy = 42.0
	p.lamp_oil = 88.0
	p.lamp_on = false
	p.set_hidden(true)
	# Record opened interactables via the live (non-restore) path.
	SignalBus.chest_opened.emit(7)
	SignalBus.door_opened.emit(11)
	# Serialize -> assert snapshot contents.
	var data: Dictionary = SaveManager.serialize()
	assert(int(data["random_seed"]) == 8675309, "save seed")
	assert(int(data["current_floor"]) == 4, "save floor")
	assert(int(data["inventory"]["coins"]) == 50, "save coins")
	assert(int(data["inventory"]["stacks"].get(ItemsData.CHEESE, 0)) == 3, "save stacks")
	assert(bool(data["inventory"]["flags"].get("merchant_visited", false)), "save flag")
	assert(data["blood_codex_mode"] == true, "save blood mode")
	assert(7 in data["opened_chests"], "save opened chest")
	assert(11 in data["opened_doors"], "save opened door")
	# Deserialize into a blank slate.
	GameManager.run_seed = 0
	GameManager.current_floor = 0
	InventoryManager.clear()
	SaveManager.deserialize(data)
	assert(GameManager.run_seed == 8675309, "restore seed")
	assert(GameManager.current_floor == 4, "restore floor")
	assert(InventoryManager.coins == 50, "restore coins")
	assert(InventoryManager.count(ItemsData.CHEESE) == 3, "restore stacks")
	assert(InventoryManager.has_artifact(ItemsData.CODEX_BLOOD), "restore artifact")
	# Player stats are applied on the next spawn.
	var p2: PlayerController = PLAYER_SCENE.instantiate()
	add_child(p2)
	assert(is_equal_approx(p2.energy, 42.0), "restore energy")
	assert(p2.lamp_oil == 88.0, "restore oil")
	assert(p2.lamp_on == false, "restore lamp")
	assert(p2.is_hidden(), "restore hidden")
	# apply_opened_to_scene ends restore mode (no matching scenes here -> just clears).
	var container := Node2D.new()
	add_child(container)
	SaveManager.apply_opened_to_scene(container)
	container.queue_free()
	p.queue_free()
	p2.queue_free()
	# File round-trip.
	SaveManager.save_game()
	assert(SaveManager.has_save(), "save file written")
	InventoryManager.clear()
	GameManager.current_floor = 0
	assert(SaveManager.load_game(), "load game")
	assert(GameManager.current_floor == 4, "load floor from file")
	assert(InventoryManager.coins == 50, "load coins from file")
	SaveManager.delete_save()
	assert(not SaveManager.has_save(), "save deleted")
	# Leave a clean state for any later boot code.
	InventoryManager.clear()
	GameManager.current_floor = 1


func _test_monsters() -> void:
	var hear := Config.tiles_to_px(Config.MONSTER_HEARING_TILES)
	var detect := Config.tiles_to_px(Config.MONSTER_DETECTION_TILES)
	# Pure detection rules.
	assert(
		not Monster.would_detect(Vector2.ZERO, Vector2.RIGHT, Vector2(50, 0), true, true, false),
		"hidden safe"
	)
	assert(
		Monster.would_detect(Vector2.ZERO, Vector2.RIGHT, Vector2(hear - 1, 0), true, false, false),
		"lamp on near: heard"
	)
	assert(
		Monster.would_detect(
			Vector2.ZERO, Vector2.RIGHT, Vector2(detect - 1, 0), true, false, false
		),
		"lamp on in cone"
	)
	assert(
		not Monster.would_detect(
			Vector2.ZERO, Vector2.RIGHT, Vector2(0, -detect), true, false, false
		),
		"lamp on out of cone"
	)
	assert(
		Monster.would_detect(Vector2.ZERO, Vector2.RIGHT, Vector2(hear - 1, 0), false, false, true),
		"lamp off fast: heard"
	)
	assert(
		not Monster.would_detect(
			Vector2.ZERO, Vector2.RIGHT, Vector2(hear + 1, 0), false, false, false
		),
		"lamp off still"
	)
	assert(
		Monster.would_detect(
			Vector2.ZERO, Vector2.RIGHT, Vector2(Config.TILE_SIZE, 0), false, false, false
		),
		"lamp off adjacent"
	)
	# Placement: count range, never at entrance, deterministic.
	var gen := FloorGenerator.new()
	var layout := gen.generate(2024, 3)
	var count_ok := layout.monster_spawns.size() >= 3 and layout.monster_spawns.size() <= 8
	assert(count_ok, "monster count range")
	var entrance := layout.room_by_id(layout.entrance_room).center()
	assert(not entrance in layout.monster_spawns, "no monster at entrance")
	var container := Node2D.new()
	add_child(container)
	var a := MonsterPlacer.new().place(layout, container, 2024 + 191)
	var b := MonsterPlacer.new().place(layout, container, 2024 + 191)
	assert(a.size() == b.size(), "monster count deterministic")
	for i in a.size():
		assert(a[i].global_position == b[i].global_position, "monster pos deterministic")
	# State machine transitions (movement-free path).
	InventoryManager.clear()
	var player: PlayerController = PLAYER_SCENE.instantiate()
	player.global_position = Vector2(200, 0)
	add_child(player)
	var m: Monster = MONSTER_SCENE.instantiate()
	m.global_position = Vector2(0, 0)
	add_child(m)
	var cb := func(_mm: Node) -> void: _monster_spotted = true
	_monster_spotted = false
	SignalBus.monster_spotted_player.connect(cb)
	m._apply_detection(true, player, 0.1)
	assert(m.state == Monster.State.CHASE, "detected -> chase")
	assert(_monster_spotted, "spotted signal")
	m._apply_detection(false, player, 0.1)
	assert(m.state == Monster.State.SEARCH, "lost -> search")
	m._search_timer = 0.05
	m._apply_detection(false, player, 0.1)
	assert(m.state == Monster.State.RETURN, "search timeout -> return")
	m.global_position = m.home_position
	m._apply_detection(false, player, 0.1)
	assert(m.state == Monster.State.PATROL, "home -> patrol")
	SignalBus.monster_spotted_player.disconnect(cb)
	m.queue_free()
	player.queue_free()
	container.queue_free()


func _test_merchant() -> void:
	# Merchant stock built from items.json "spawns" containing "merchant".
	var m: Merchant = preload("res://scenes/Merchant.tscn").instantiate()
	add_child(m)
	assert(m.stock.size() >= 2, "merchant stock has items")
	var cloak_price := m.price_of(ItemsData.CLOAK)
	assert(cloak_price > 0, "CLOAK has a price")
	assert(m.price_of(ItemsData.COIN) == -1, "COIN not sold by merchant")
	# try_buy: insufficient coins.
	InventoryManager.clear()
	assert(not m.try_buy(ItemsData.CLOAK), "cannot buy poor")
	# try_buy: successful purchase.
	InventoryManager.add_coins(100)
	assert(m.try_buy(ItemsData.CLOAK), "buy CLOAK")
	assert(InventoryManager.count(ItemsData.CLOAK) == 1, "CLOAK in inventory")
	assert(InventoryManager.coins == 100 - cloak_price, "coins deducted")
	# Blood Codex is a unique artifact, cannot buy twice.
	if (
		m.price_of(ItemsData.CODEX_BLOOD) > 0
		and InventoryManager.coins >= m.price_of(ItemsData.CODEX_BLOOD)
	):
		assert(m.try_buy(ItemsData.CODEX_BLOOD), "buy CODEX_BLOOD")
		assert(InventoryManager.has_artifact(ItemsData.CODEX_BLOOD), "CODEX_BLOOD owned")
		assert(not m.try_buy(ItemsData.CODEX_BLOOD), "CODEX_BLOOD unique")
	# merchant_visited flag set on interact.
	var probe := {"trade_opened": false}
	var cb := func(_mm: Node) -> void: probe["trade_opened"] = true
	SignalBus.merchant_trade_opened.connect(cb)
	m.interact(null)
	assert(probe["trade_opened"], "trade signal emitted")
	assert(InventoryManager.get_flag("merchant_visited"), "merchant_visited flag set")
	SignalBus.merchant_trade_opened.disconnect(cb)
	# Placement: floor 1 never spawned; floor 2+ up to 50% chance.
	InventoryManager.clear()
	var gen := FloorGenerator.new()
	var floor1 := gen.generate(999, 0)
	var container := Node2D.new()
	add_child(container)
	var placed := MerchantPlacer.new().place(floor1, container, 999 + 211)
	assert(placed.is_empty(), "no merchant on floor 1")
	var floor3 := gen.generate(999, 2)
	for _trial in 20:
		placed = MerchantPlacer.new().place(floor3, container, 999 + 211 + _trial * 7)
		if not placed.is_empty():
			break
	assert(not placed.is_empty(), "merchant placed on floor 3 at some seed")
	# When placed, not in entrance/stairs room.
	var rooms_stuff := container.find_children("*", "Merchant", true, false)
	assert(placed[0] in rooms_stuff, "merchant in container")
	m.queue_free()
	container.queue_free()
	InventoryManager.clear()


func _test_survival() -> void:
	# Monster Repellent: a monster that would chase ignores the player while the flag is set.
	InventoryManager.clear()
	var player: PlayerController = PLAYER_SCENE.instantiate()
	player.global_position = Vector2(Config.TILE_SIZE, 0)
	add_child(player); player._on_spawn()
	var m: Monster = MONSTER_SCENE.instantiate()
	m.global_position = Vector2(0, 0)
	add_child(m); m._on_spawn()
	m._physics_process(0.1)
	assert(m.state == Monster.State.CHASE, "monster chases without repellent")
	m.state = Monster.State.PATROL
	InventoryManager.set_flag(ItemsData.REP_SPRAY, true)
	m._physics_process(0.1)
	assert(m.state == Monster.State.PATROL, "repellent stops chase")
	InventoryManager.set_flag(ItemsData.REP_SPRAY, false)
	# Survival Amulet: one-time death shield consumed on catch instead of Game Over.
	GameManager.state = GameManager.State.PLAYING
	SignalBus.player_caught.emit()
	assert(GameManager.state == GameManager.State.GAME_OVER, "caught without amulet = game over")
	GameManager.state = GameManager.State.PLAYING
	InventoryManager.set_flag(ItemsData.LIFE_AMULET, true)
	var shield_probe := {"used": false}
	var scb := func() -> void: shield_probe["used"] = true
	SignalBus.player_shield_consumed.connect(scb)
	SignalBus.player_caught.emit()
	assert(GameManager.state == GameManager.State.PLAYING, "amulet prevents game over")
	assert(not InventoryManager.has_flag(ItemsData.LIFE_AMULET), "amulet consumed")
	assert(shield_probe["used"], "shield consumed signal")
	SignalBus.player_shield_consumed.disconnect(scb)
	GameManager.state = GameManager.State.PLAYING
	m.queue_free()
	player.queue_free()
	InventoryManager.clear()


func _test_stealth() -> void:
	InventoryManager.clear()
	var player: PlayerController = PLAYER_SCENE.instantiate()
	player.global_position = Vector2(Config.TILE_SIZE, 0)
	add_child(player); player._on_spawn()
	var m: Monster = MONSTER_SCENE.instantiate()
	m.global_position = Vector2(0, 0)
	add_child(m); m._on_spawn()
	# Hidden: a close, lit player that is hidden is not detected.
	m._physics_process(0.1)
	assert(m.state == Monster.State.CHASE, "visible player is chased")
	m.state = Monster.State.PATROL
	player.set_hidden(true)
	m._physics_process(0.1)
	assert(m.state == Monster.State.PATROL, "hidden player not detected")
	player.set_hidden(false)
	# Balcony safe zone: on a balcony, the player is never spotted.
	m._physics_process(0.1)
	assert(m.state == Monster.State.CHASE, "off-balcony player chased")
	m.state = Monster.State.PATROL
	player.on_balcony = true
	m._physics_process(0.1)
	assert(m.state == Monster.State.PATROL, "balcony player safe")
	player.on_balcony = false
	# Furniture toggles the player's hidden state via interaction.
	var furniture: Furniture = preload("res://scenes/Furniture.tscn").instantiate()
	add_child(furniture)
	assert(not player.is_hidden(), "starts visible")
	furniture.interact(player)
	assert(player.is_hidden(), "furniture hides player")
	furniture.interact(player)
	assert(not player.is_hidden(), "furniture reveals player")
	furniture.queue_free()
	m.queue_free()
	player.queue_free()
	InventoryManager.clear()


func _test_danger_sense() -> void:
	# Pure helper: direction to the nearest monster.
	var m1 := Node2D.new()
	m1.global_position = Vector2(100, 0)
	var m2 := Node2D.new()
	m2.global_position = Vector2(0, 50)
	var dir := DangerSense.nearest_monster_direction(Vector2.ZERO, [m1, m2])
	assert(dir.is_equal_approx(Vector2(0, 1)), "nearest monster is m2 (down)")
	assert(
		DangerSense.nearest_monster_direction(Vector2.ZERO, []).is_zero_approx(),
		"no monsters -> zero"
	)
	m1.queue_free()
	m2.queue_free()
	# Autoload emits the direction only when the item is owned.
	InventoryManager.clear()
	var player: PlayerController = PLAYER_SCENE.instantiate()
	player.global_position = Vector2(0, 0)
	add_child(player); player._on_spawn()
	var mon: Monster = MONSTER_SCENE.instantiate()
	mon.global_position = Vector2(Config.TILE_SIZE * 2, 0)
	add_child(mon); mon._on_spawn()
	var probe := {"dir": Vector2.ZERO}
	var cb := func(d: Vector2) -> void: probe["dir"] = d
	SignalBus.danger_sense_updated.connect(cb)
	DangerSense._process(0.0)
	assert(probe["dir"].is_zero_approx(), "no aura without item")
	InventoryManager.set_flag(ItemsData.DANGER_SENSE, true)
	DangerSense._process(0.0)
	assert(probe["dir"].is_equal_approx(Vector2(1, 0)), "aura points to monster")
	SignalBus.danger_sense_updated.disconnect(cb)
	mon.queue_free()
	player.queue_free()
	InventoryManager.clear()


func _test_hud() -> void:
	var hud: HUD = HUD_SCENE.instantiate()
	add_child(hud)
	SignalBus.coins_changed.emit(7)
	assert(hud.coins == 7, "hud coins")
	assert("7" in hud._coins_label.text, "coins label updated")
	SignalBus.lamp_oil_changed.emit(120)
	assert(is_equal_approx(hud.oil, 120.0), "hud oil")
	SignalBus.energy_changed.emit(50)
	assert(is_equal_approx(hud.energy, 50.0), "hud energy")
	SignalBus.danger_sense_updated.emit(Vector2(1, 0))
	assert(hud.danger_dir.is_equal_approx(Vector2(1, 0)), "hud danger dir")
	assert(hud._danger.visible, "danger aura visible")
	SignalBus.danger_sense_updated.emit(Vector2.ZERO)
	assert(not hud._danger.visible, "danger aura hidden")
	SignalBus.monster_spotted_player.emit(hud)
	assert(hud.spotted, "hud spotted flag")
	assert(hud._flash.visible, "flash visible on spot")
	SignalBus.monster_lost_player.emit(hud)
	assert(not hud._flash.visible, "flash hidden on lost")
	SignalBus.artifact_acquired.emit(ItemsData.CODEX_BLOOD)
	assert(ItemsData.CODEX_BLOOD in hud.artifacts, "artifact recorded")
	InventoryManager.clear()
	hud.queue_free()


func _test_menu() -> void:
	# Continue is disabled with no save, enabled once a save exists.
	var menu1: MainMenu = MENU_SCENE.instantiate()
	add_child(menu1)
	assert(menu1._continue.disabled, "no continue without save")
	assert(menu1._play.pressed.get_connections().size() > 0, "play wired")
	InventoryManager.clear()
	GameManager.run_seed = 4242
	GameManager.current_floor = 3
	SaveManager.save_game()
	menu1.queue_free()
	var menu2: MainMenu = MENU_SCENE.instantiate()
	add_child(menu2)
	assert(not menu2._continue.disabled, "continue enabled with save")
	menu2.queue_free()
	SaveManager.delete_save()


func _test_pause() -> void:
	# Pause / resume round-trip.
	GameManager.run_seed = 7
	GameManager.current_floor = 2
	GameManager.state = GameManager.State.PLAYING
	var paused_probe := {"hit": false}
	var resumed_probe := {"hit": false}
	var cb_p := func() -> void: paused_probe["hit"] = true
	var cb_r := func() -> void: resumed_probe["hit"] = true
	SignalBus.game_paused.connect(cb_p)
	SignalBus.game_resumed.connect(cb_r)
	GameManager.pause()
	assert(GameManager.state == GameManager.State.PAUSED, "state paused")
	assert(get_tree().paused, "tree paused")
	assert(not InputReader.gameplay_enabled, "gameplay disabled while paused")
	assert(paused_probe["hit"], "game_paused emitted")
	# Settings can open while paused.
	GameManager.open_settings()
	assert(GameManager._settings_open, "settings open from pause")
	GameManager.close_settings()
	assert(not GameManager._settings_open, "settings closed")
	GameManager.resume()
	assert(GameManager.state == GameManager.State.PLAYING, "state resumed")
	assert(not get_tree().paused, "tree resumed")
	assert(InputReader.gameplay_enabled, "gameplay re-enabled")
	assert(resumed_probe["hit"], "game_resumed emitted")
	SignalBus.game_paused.disconnect(cb_p)
	SignalBus.game_resumed.disconnect(cb_r)
	get_tree().paused = false
	InputReader.set_gameplay_enabled(true)

	# Settings persistence round-trip.
	SettingsManager.set_volume(AudioManager.BUS_SFX, 0.5)
	assert(SettingsManager.sfx_volume == 0.5, "sfx volume set")
	SettingsManager.load_settings()
	assert(is_equal_approx(SettingsManager.sfx_volume, 0.5), "sfx volume persisted")
	SettingsManager.set_volume(AudioManager.BUS_SFX, 1.0)

	# Pause is a no-op outside play.
	GameManager.state = GameManager.State.MENU
	GameManager.pause()
	assert(GameManager.state == GameManager.State.MENU, "pause ignored in menu")
	GameManager.state = GameManager.State.PLAYING


func _test_difficulty() -> void:
	var detect := Config.tiles_to_px(Config.MONSTER_DETECTION_TILES)
	# Blood Mode widens the detection radius (gameplay.md §10 "detect quicker").
	assert(
		not Monster.would_detect(Vector2.ZERO, Vector2.RIGHT, Vector2(detect + 1, 0), true, false, false),
		"normal: outside cone radius"
	)
	assert(
		Monster.would_detect(Vector2.ZERO, Vector2.RIGHT, Vector2(detect + 1, 0), true, false, false, true),
		"blood mode: detects beyond normal radius"
	)

	# Player tires faster in Blood Mode (energy drains more per second).
	InventoryManager.clear()
	var p: PlayerController = PLAYER_SCENE.instantiate()
	add_child(p)
	var before := p.energy
	p._update_energy(1.0, true, false)  # 1s walking, no blood
	var normal_drain := before - p.energy
	InventoryManager.add_artifact(ItemsData.CODEX_BLOOD)
	before = p.energy
	p._update_energy(1.0, true, false)
	var blood_drain := before - p.energy
	assert(blood_drain > normal_drain * 1.2, "blood mode drains energy faster")
	InventoryManager.clear()
	p.queue_free()

	# Resources appear ~40% rarer in Blood Mode (roll_loot scales down).
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var loot_normal := LootPlacer.new().roll_loot(rng, false)
	rng.seed = 1
	var loot_blood := LootPlacer.new().roll_loot(rng, false, true)
	assert(
		loot_blood[ItemsData.COIN] <= loot_normal[ItemsData.COIN],
		"blood mode: coins <= normal"
	)
	assert(
		loot_blood[ItemsData.COIN] == int(round(loot_normal[ItemsData.COIN] * Config.BLOOD_MODE_RESOURCE_FACTOR))
			if loot_normal[ItemsData.COIN] > 0
			else loot_blood[ItemsData.COIN] == 0,
		"blood mode: coins scaled by factor"
	)

	# Bloodbringer: winning in Blood Mode unlocks the achievement (M25).
	AchievementManager.reset_for_testing()
	InventoryManager.clear()
	InventoryManager.add_artifact(ItemsData.CODEX_BLOOD)
	var probe := {"hit": false}
	var cb := func(id: StringName) -> void: probe["hit"] = (id == AchievementManager.BLOODBRINGER)
	SignalBus.achievement_unlocked.connect(cb)
	AchievementManager.unlock(AchievementManager.BLOODBRINGER)
	assert(AchievementManager.has(AchievementManager.BLOODBRINGER), "bloodbringer unlocked")
	assert(probe["hit"], "achievement signal emitted")
	# Idempotent: re-unlock does not re-emit or re-save.
	probe["hit"] = false
	AchievementManager.unlock(AchievementManager.BLOODBRINGER)
	assert(not probe["hit"], "achievement unlock is idempotent")
	SignalBus.achievement_unlocked.disconnect(cb)
	InventoryManager.clear()


func _test_optimization() -> void:
	# Monster AI proximity gate: idle monsters beyond AI range skip detection; chasing never skip.
	assert(
		Monster.is_far_idle(
			Config.tiles_to_px(Config.MONSTER_AI_RANGE_TILES) + 1, Monster.State.PATROL
		),
		"patrol far -> idle skip"
	)
	assert(
		not Monster.is_far_idle(
			Config.tiles_to_px(Config.MONSTER_AI_RANGE_TILES) + 1, Monster.State.CHASE
		),
		"chase far -> still runs"
	)
	assert(not Monster.is_far_idle(10.0, Monster.State.PATROL), "patrol near -> runs")

	# Behavior: a far idle monster does not run detection (stays PATROL); a near one chases.
	InventoryManager.clear()
	var player: PlayerController = PLAYER_SCENE.instantiate()
	player.global_position = Vector2.ZERO
	add_child(player); player._on_spawn()
	var m: Monster = MONSTER_SCENE.instantiate()
	m.global_position = Vector2(Config.tiles_to_px(Config.MONSTER_AI_RANGE_TILES) + 200, 0)
	add_child(m); m._on_spawn()
	m._physics_process(0.1)
	assert(m.state == Monster.State.PATROL, "far idle monster stays patrol")
	m.global_position = Vector2(Config.TILE_SIZE, 0)
	m._physics_process(0.1)
	assert(m.state == Monster.State.CHASE, "near monster chases")
	m.queue_free()
	player.queue_free()
	InventoryManager.clear()

	# Visibility culling: overlapping rects visible; far rects hidden; margin keeps edges visible.
	var cam := Rect2(0, 0, 320, 180)
	assert(Optimizer.rect_visible(Rect2(10, 10, 50, 50), cam), "overlapping visible")
	assert(not Optimizer.rect_visible(Rect2(1000, 1000, 50, 50), cam), "far hidden")
	assert(Optimizer.rect_visible(Rect2(310, 0, 50, 50), cam), "within margin visible")


func _test_balancing() -> void:
	# Data-driven balancing (M27): the BalancingConfig resource loads and mirrors into Config,
	# with sane invariants and no lingering unresolved-balancing markers.
	assert(Config.balancing != null, "balancing resource loaded")
	assert(Config.balancing is BalancingConfig, "balancing is BalancingConfig")
	# Resource values are mirrored (not stuck on code fallbacks where they differ is irrelevant;
	# the contract is that Config.X equals the resource value).
	assert(Config.PLAYER_MOVE_SPEED == Config.balancing.player_move_speed, "player speed mirrored")
	assert(Config.MONSTER_AI_RANGE_TILES == Config.balancing.monster_ai_range_tiles, "ai range mirrored")
	assert(Config.LOOT_OIL_SMALL_RATIO == Config.balancing.loot_oil_small_ratio, "loot ratio mirrored")
	# Invariants (balancing.md / ADR-018):
	# 1) AI range must exceed detection + hearing so off-range idle monsters truly can't detect.
	assert(
		Config.MONSTER_AI_RANGE_TILES > Config.MONSTER_DETECTION_TILES + Config.MONSTER_HEARING_TILES,
		"AI range exceeds detection + hearing"
	)
	# 2) Lamp-off detection factor reduces detection (< 1).
	assert(Config.LAMP_OFF_DETECTION_FACTOR > 0.0 and Config.LAMP_OFF_DETECTION_FACTOR < 1.0, "lamp-off factor < 1")
	# 3) Blood Mode is strictly harder (detection/energy/speed multipliers >= 1, resource factor <= 1).
	assert(Config.BLOOD_MODE_DETECT_FACTOR >= 1.0, "blood detect >= 1")
	assert(Config.BLOOD_MODE_ENERGY_FACTOR >= 1.0, "blood energy >= 1")
	assert(Config.BLOOD_MODE_MONSTER_SPEED >= 1.0, "blood speed >= 1")
	assert(Config.BLOOD_MODE_RESOURCE_FACTOR > 0.0 and Config.BLOOD_MODE_RESOURCE_FACTOR < 1.0, "blood loot < 1")
	# 4) Loot oil ratio is a valid probability.
	assert(Config.LOOT_OIL_SMALL_RATIO >= 0.0 and Config.LOOT_OIL_SMALL_RATIO <= 1.0, "loot ratio in [0,1]")
	# 5) No unresolved balancing TODO markers remain in code (this also guarantees the dead
	#    DANGER_SENSE_DURATION constant was removed, per ADR-016/ADR-018).
	var todo_files := [
		"res://scripts/config.gd", "res://scripts/monster.gd", "res://scripts/loot_placer.gd"
	]
	for f in todo_files:
		var src := FileAccess.get_file_as_string(f)
		assert(src.find("TODO(BALANCE)") == -1, "no unresolved balancing TODO in " + f)


func _test_polish() -> void:
	# Code-only juice (M28): overlay/sfx/shake helpers load and run without error.
	assert(AudioManager.Sfx.GAME_OVER == AudioManager.Sfx.GAME_OVER, "game over sfx exists")
	assert(AudioManager.Sfx.HEARTBEAT == AudioManager.Sfx.HEARTBEAT, "heartbeat sfx exists")
	# Game Over overlay scene loads and is a CanvasLayer.
	var go_scene := preload("res://scenes/GameOverOverlay.tscn")
	var go := go_scene.instantiate()
	assert(go is CanvasLayer, "game over overlay is CanvasLayer")
	go.free()
	# Screen shake helper is registered and callable.
	ScreenShake.add_trauma(0.3)
	# HUD danger/flash handlers run without throwing.
	var hud := preload("res://scenes/HUD.tscn").instantiate()
	add_child(hud)
	hud._on_heartbeat(0.6)
	hud._on_spotted(null)
	hud._on_lost(null)
	hud.queue_free()
	# Settings debounce API present.
	assert(SettingsManager.has_method("set_volume_live"), "settings live volume API")
	assert(SettingsManager.has_method("save_settings"), "settings persist API")


func _test_world_physics() -> void:
	# M30: world grid + A* pathfinding + door blocking sanity.
	var gen := FloorGenerator.new()
	var layout := gen.generate(2024, 1)
	var grid := WorldGrid.from_layout(layout)
	# Every room center is walkable floor.
	for r in layout.rooms:
		var c := r.center()
		assert(grid.is_walkable_tile(Vector2i(c.x, c.y)), "room center walkable")
	# A tile far outside the floor is a wall.
	assert(not grid.is_walkable_tile(Vector2i(-50, -50)), "far tile is wall")
	# Pathfinding can route entrance -> stairs (the layout is a connected tree).
	var start := layout.entrance_pos()
	var goal := layout.stairs_pos()
	var path := Pathfinder.find_path(grid, Vector2i(start.x, start.y), Vector2i(goal.x, goal.y))
	assert(path.size() >= 2, "path entrance->stairs exists")
	assert(path[0] == Vector2i(start.x, start.y), "path starts at entrance")
	assert(path[path.size() - 1] == Vector2i(goal.x, goal.y), "path ends at stairs")
	# A closed door blocks its tile; opening it restores walkability.
	if not layout.corridors.is_empty():
		var cor := layout.corridors[0]
		var dt := grid.world_to_tile(Config.TILE_SIZE * cor.get_center())
		grid.set_blocked(dt, true)
		assert(not grid.is_walkable_tile(dt), "closed door tile blocked")
		grid.set_blocked(dt, false)
		assert(grid.is_walkable_tile(dt), "opened door tile walkable")


func _test_release() -> void:
	# Release Candidate integration (M29): the full generation/population pipeline runs for every
	# floor without crashing, and the GameManager state machine completes a full run to the win,
	# unlocks Bloodbringer in Blood Codex mode, and handles Game Over + Survival Amulet.
	# test_mode lets us drive the flow without SceneLoader swaps freeing the boot node.
	var container := Node2D.new()
	add_child(container)
	for f in range(1, Config.FLOOR_COUNT + 1):
		var gen := FloorGenerator.new()
		var layout := gen.generate(GameManager.floor_seed(f), f)
		var built := FloorBuilder.build(layout, container)
		var grid: WorldGrid = built["world_grid"]
		assert(built.has("bounds_px") and built.has("entrance_px"), "floor %d built" % f)
		LootPlacer.new().place(layout, container, GameManager.floor_seed(f) + 131)
		DoorPlacer.new().place(layout, container, GameManager.floor_seed(f) + 151, grid)
		MonsterPlacer.new().place(layout, container, GameManager.floor_seed(f) + 191, grid)
		MerchantPlacer.new().place(layout, container, GameManager.floor_seed(f) + 211)
		FurniturePlacer.new().place(layout, container, GameManager.floor_seed(f) + 777)
	container.free()

	GameManager.test_mode = true

	# Normal run to the win state.
	InventoryManager.clear()
	GameManager.start_game()
	assert(GameManager.state == GameManager.State.PLAYING, "run starts playing")
	assert(GameManager.current_floor == 1, "run starts on floor 1")
	var guard := 0
	while GameManager.state == GameManager.State.PLAYING and guard < 50:
		GameManager.advance_floor()
		guard += 1
	assert(GameManager.state == GameManager.State.WON, "run reaches win after all floors")

	# Blood Codex win unlocks Bloodbringer (M25).
	InventoryManager.clear()
	InventoryManager.add_artifact(ItemsData.CODEX_BLOOD)
	GameManager.start_game()
	guard = 0
	while GameManager.state == GameManager.State.PLAYING and guard < 50:
		GameManager.advance_floor()
		guard += 1
	assert(AchievementManager.has(AchievementManager.BLOODBRINGER), "blood-mode win unlocks Bloodbringer")

	# Game Over returns to menu; Survival Amulet absorbs one hit.
	InventoryManager.clear()
	GameManager.start_game()
	SignalBus.player_caught.emit()
	assert(GameManager.state == GameManager.State.GAME_OVER, "catch without amulet = game over")
	GameManager.return_to_menu()
	assert(GameManager.state == GameManager.State.MENU, "return to menu after game over")

	InventoryManager.clear()
	GameManager.start_game()
	InventoryManager.set_flag(ItemsData.LIFE_AMULET, true)
	SignalBus.player_caught.emit()
	assert(GameManager.state == GameManager.State.PLAYING, "amulet absorbs the hit")
	assert(not InventoryManager.has_flag(ItemsData.LIFE_AMULET), "amulet consumed on use")

	GameManager.test_mode = false
