class_name Monster
extends BaseEntity
## Roaming threat (M17). State machine: Patrol -> Detect -> Chase -> Search -> Return.
## Pure detection helper would_detect(); movement is straight-line placeholder until A* pathfinding
## arrives (M26). Caught = instant Game Over (emits SignalBus.player_caught).
## See docs/roadmap.md M17, docs/monster.md, docs/gameplay-summary.md §4.
##
## All tunables are resolved and sourced from the BalancingConfig resource
## (res://config/balancing.tres, M27). Conflict resolutions: sight radius 8 tiles (C3);
## chase speed 140 < player run 180 is intentional (C4, ADR-013); detection factors set (C9).
## Survival items (M19): Monster Repellent (REP_SPRAY flag) blocks detection; Survival Amulet
## (LIFE_AMULET flag) is a one-time death shield consumed in GameManager on player_caught.
## Stealth (M20): hidden players and players on balconies are never detected.

enum State { PATROL, CHASE, SEARCH, RETURN }

const CATCH_RADIUS_PX: float = 12.0  # overlap with player = caught (matches 32px collision)

var state: int = State.PATROL
var home_position: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.RIGHT

var _search_timer: float = 0.0
var _pause_timer: float = 0.0
var _wander_dir: Vector2 = Vector2.RIGHT

# M30: grid + A* pathfinding so the monster follows corridors instead of walking through walls.
var world_grid: WorldGrid = null
var _path: Array[Vector2i] = []
var _path_goal: Vector2i = Vector2i.ZERO
var _repath_cooldown: float = 0.0


func _on_spawn() -> void:
	add_to_group("monster")
	home_position = global_position
	SignalBus.monster_state_changed.emit(self, state)


## Pure detection: would this monster spot the player given the world state?
## Hidden (in furniture) is always safe. Lamp on -> vision cone + hearing; lamp off -> hearing only.
## `blood_mode` widens both radii (Blood Codex makes monsters detect quicker, gameplay.md §10).
static func would_detect(
	monster_pos: Vector2,
	face: Vector2,
	player_pos: Vector2,
	lamp_on: bool,
	player_hidden: bool,
	player_moving_fast: bool,
	blood_mode: bool = false
) -> bool:
	if player_hidden:
		return false
	var detect_px := Config.tiles_to_px(Config.MONSTER_DETECTION_TILES)
	var hear_px := Config.tiles_to_px(Config.MONSTER_HEARING_TILES)
	if blood_mode:
		detect_px *= Config.BLOOD_MODE_DETECT_FACTOR
		hear_px *= Config.BLOOD_MODE_DETECT_FACTOR
	var to := player_pos - monster_pos
	var dist := to.length()
	if lamp_on:
		if dist <= hear_px:
			return true
		if dist <= detect_px and face != Vector2.ZERO:
			var ang := rad_to_deg(face.angle_to(to))
			return abs(ang) <= Config.MONSTER_VISION_ANGLE_DEG / 2.0
		return false
	# Lamp off: hearing only. Fast movement within earshot, or adjacency.
	if player_moving_fast and dist <= hear_px:
		return true
	return dist <= float(Config.TILE_SIZE)


func _physics_process(delta: float) -> void:
	var player := _find_player()
	var detected := false
	if player != null and is_instance_valid(player):
		# M26: idle monsters beyond AI range skip the (cheap-at-scale) detection
		# cone math. Detection radius (8) + hearing (4) are both < AI_RANGE (12),
		# so a far idle monster can never detect anyway; skipping keeps correctness while
		# cutting per-frame cost on large floors. Chasing/searching monsters always run.
		var dist_px := global_position.distance_to(player.global_position)
		var far_idle := (
			(state == State.PATROL or state == State.RETURN)
			and dist_px > Config.tiles_to_px(Config.MONSTER_AI_RANGE_TILES)
		)
		if not far_idle:
			detected = would_detect(
				global_position,
				facing,
				player.global_position,
				player.lamp_on,
				player.is_hidden(),
				player.velocity.length() > Config.PLAYER_MOVE_SPEED,
				InventoryManager.has_artifact(ItemsData.CODEX_BLOOD)
			)
			# M19: Monster Repellent makes the player undetectable (monster loses interest).
			if detected and InventoryManager.has_flag(ItemsData.REP_SPRAY):
				detected = false
			# M20: balconies are safe zones — monsters never spot the player there.
			if detected and player != null and player.get("on_balcony", false):
				detected = false
		_emit_heartbeat(player)
	_apply_detection(detected, player, delta)


func _emit_heartbeat(player: Node) -> void:
	var dist := global_position.distance_to(player.global_position)
	var detect_px := Config.tiles_to_px(Config.MONSTER_DETECTION_TILES)
	if dist <= detect_px:
		SignalBus.heartbeat_triggered.emit(1.0 - dist / detect_px)


## Drive the state machine for one tick. Exposed for unit testing without the physics loop.
func _apply_detection(detected: bool, player: Node, delta: float) -> void:
	if detected:
		if state != State.CHASE:
			_set_state(State.CHASE)
			AudioManager.play_sfx(AudioManager.Sfx.DETECTION)
			SignalBus.monster_spotted_player.emit(self)
		_chase(player, delta)
		return
	match state:
		State.CHASE:
			_set_state(State.SEARCH)
			_search_timer = Config.MONSTER_SEARCH_TIME
			SignalBus.monster_lost_player.emit(self)
		State.SEARCH:
			_search_timer -= delta
			velocity = Vector2.ZERO
			if _search_timer <= 0.0:
				_set_state(State.RETURN)
		State.RETURN:
			_move_toward(home_position, Config.MONSTER_PATROL_SPEED, delta)
			if global_position.distance_to(home_position) < 2.0:
				_set_state(State.PATROL)
		State.PATROL:
			_roam(delta)


func _chase(player: Node, delta: float) -> void:
	if player == null or not is_instance_valid(player):
		_roam(delta)
		return
	var speed := Config.MONSTER_CHASE_SPEED * _blood_speed()
	if world_grid == null:
		# Fallback (e.g. self-tests): straight-line pursuit.
		_move_toward(player.global_position, speed, delta)
	else:
		_repath_cooldown -= delta
		var goal_tile := world_grid.world_to_tile(player.global_position)
		if _repath_cooldown <= 0.0 or goal_tile != _path_goal or _path.is_empty():
			_path = Pathfinder.find_path(world_grid, world_grid.world_to_tile(global_position), goal_tile)
			_path_goal = goal_tile
			_repath_cooldown = 0.25
		var aim := player.global_position
		while _path.size() >= 2:
			var nxt := world_grid.tile_to_world_center(_path[1])
			if global_position.distance_to(nxt) < Config.TILE_SIZE * 0.5:
				_path.remove_at(1)
			else:
				aim = nxt
				break
		_move_toward(aim, speed, delta)
	if global_position.distance_to(player.global_position) <= CATCH_RADIUS_PX:
		SignalBus.player_caught.emit()


func _roam(delta: float) -> void:
	if _pause_timer > 0.0:
		_pause_timer -= delta
		velocity = Vector2.ZERO
		return
	var speed := Config.MONSTER_PATROL_SPEED
	if world_grid == null:
		_move_toward(global_position + _wander_dir * 16.0, speed, delta)
	else:
		# Pick a wander goal near home and path to it; recompute periodically.
		if _path.is_empty() or global_position.distance_to(world_grid.tile_to_world_center(_path_goal)) < 10.0:
			_path_goal = _random_walkable_near(home_position, Config.MONSTER_HEARING_TILES)
			_path = Pathfinder.find_path(world_grid, world_grid.world_to_tile(global_position), _path_goal)
		_repath_cooldown -= delta
		if _repath_cooldown <= 0.0:
			_path = Pathfinder.find_path(world_grid, world_grid.world_to_tile(global_position), _path_goal)
			_repath_cooldown = 0.5
		var aim := world_grid.tile_to_world_center(_path_goal)
		while _path.size() >= 2:
			var nxt := world_grid.tile_to_world_center(_path[1])
			if global_position.distance_to(nxt) < Config.TILE_SIZE * 0.5:
				_path.remove_at(1)
			else:
				aim = nxt
				break
		_move_toward(aim, speed, delta)
	# Keep monsters loosely tethered to home and occasionally repick a wander direction.
	if global_position.distance_to(home_position) > Config.tiles_to_px(Config.MONSTER_HEARING_TILES):
		_wander_dir = (home_position - global_position).normalized()
	if randf() < 0.005:
		_wander_dir = Vector2(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0).normalized()
		_pause_timer = randf_range(Config.MONSTER_ROAM_PAUSE_MIN, Config.MONSTER_ROAM_PAUSE_MAX)


## M30: choose a random walkable tile within `radius_tiles` of `center` (used for patrol roaming).
func _random_walkable_near(center: Vector2, radius_tiles: int) -> Vector2i:
	var c := world_grid.world_to_tile(center)
	for _i in 16:
		var off := Vector2i(randi_range(-radius_tiles, radius_tiles), randi_range(-radius_tiles, radius_tiles))
		var t := c + off
		if world_grid.is_walkable_tile(t):
			return t
	return c


func _move_toward(target: Vector2, speed: float, _delta: float) -> void:
	var dir := target - global_position
	if dir.length() > 1.0:
		dir = dir.normalized()
		facing = dir
		velocity = dir * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO


func _blood_speed() -> float:
	if InventoryManager.has_artifact(ItemsData.CODEX_BLOOD):
		return Config.BLOOD_MODE_MONSTER_SPEED
	return 1.0


func _set_state(next: int) -> void:
	if next == state:
		return
	state = next
	SignalBus.monster_state_changed.emit(self, state)


func _find_player() -> Node:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return null
	return nodes[0]


## M26 (pure, testable): an idle monster beyond the AI range is safe to skip detection for.
## Chasing/searching states are never skipped so a committed monster keeps its lock.
static func is_far_idle(dist_px: float, state: int) -> bool:
	return (
		state == State.PATROL or state == State.RETURN
	) and dist_px > Config.tiles_to_px(Config.MONSTER_AI_RANGE_TILES)
