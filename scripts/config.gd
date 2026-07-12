extends Node
## Global tunable constants (autoload "Config").
## Single source of truth for balancing values. No magic numbers elsewhere.
##
## As of M27 the authoritative values live in the BalancingConfig Resource
## (res://config/balancing.tres). This autoload loads it in _init() and mirrors the
## values into the static fields below, so gameplay code keeps calling Config.X unchanged.
## Edit the .tres to rebalance the game without touching gameplay code.
## The literal defaults here are fallbacks used only if the .tres is missing.
##
## See docs/balancing.md, docs/roadmap.md M27, docs/decisions.md ADR-018.

const BALANCING_PATH := "res://config/balancing.tres"

# --- Display / world (not gameplay-tunable; kept as code constants) ---
const BASE_WIDTH: int = 320
const BASE_HEIGHT: int = 180
const TARGET_FPS: int = 60
# TILE_SIZE read from ProjectSettings pixel_horror/tile_size at runtime.
static var TILE_SIZE: int = 32

# Loaded balancing resource (M27). Set in _init(); never null after boot.
static var balancing: BalancingConfig = null

# --- Player (mirrored from BalancingConfig) ---
static var PLAYER_MOVE_SPEED: float = 120.0        # px/sec
static var PLAYER_RUN_SPEED: float = 180.0         # px/sec
static var PLAYER_CROUCH_SPEED: float = 80.0       # px/sec
static var PLAYER_MAX_HEALTH: int = 100            # Unused (C5: no health system). Future use only.
static var PLAYER_MAX_ENERGY: int = 100
static var ENERGY_COST_WALK: float = 0.1           # % per sec
static var ENERGY_COST_RUN: float = 0.25           # % per sec
static var ENERGY_REGEN_PER_MIN: float = 1.0       # % per min (minimal)

# --- Lantern (gameplay.md / balancing.md) ---
static var LANTERN_OIL_START: float = 600.0        # seconds (10 min)
static var OIL_SMALL_REFILL: float = 60.0          # seconds
static var OIL_LARGE_REFILL: float = 120.0         # seconds
# Lamp off reduces how easily the player is detected (design choice; documented ADR-018).
static var LAMP_OFF_DETECTION_FACTOR: float = 0.5
# Max lantern radius in tiles (fills the 320x180 viewport at 32px). Documented ADR-018.
static var LANTERN_RADIUS_TILES: float = 5.0

# --- Lighting (art-style.md: warm light vs cool dark) ---
static var AMBIENT_DARKNESS := Color(0.08, 0.08, 0.12)
static var LANTERN_COLOR := Color(1.0, 0.85, 0.55)  # warm orange

# --- Monster (balancing.md; sight radius conflict C3 resolved) ---
static var MONSTER_PATROL_SPEED: float = 90.0      # px/sec
static var MONSTER_CHASE_SPEED: float = 140.0      # px/sec
static var MONSTER_DETECTION_TILES: float = 8.0
static var MONSTER_CHASE_TILES: float = 12.0
static var MONSTER_VISION_ANGLE_DEG: float = 110.0
static var MONSTER_HEARING_TILES: float = 4.0
# M26: idle monsters beyond this range skip detection (AI_RANGE > detection 8 + hearing 4 tiles,
# so correctness is preserved while cutting per-frame cost on large floors).
static var MONSTER_AI_RANGE_TILES: float = 13.0
static var MONSTER_ROAM_PAUSE_MIN: float = 1.0
static var MONSTER_ROAM_PAUSE_MAX: float = 3.0
static var MONSTER_SEARCH_TIME: float = 5.0

# --- Food energy (balancing.md) ---
static var FOOD_APPLE_ENERGY: int = 20
static var FOOD_COOKIE_ENERGY: int = 10
static var FOOD_CHEESE_ENERGY: int = 25
static var FOOD_PIE_ENERGY: int = 35

# --- Artifact effects (balancing.md; durations conflict C9 resolved, ADR-016) ---
static var NIGHT_VISION_DURATION: float = 120.0    # sec
static var SLEEP_MONSTER_WEAKEN: float = 0.15      # 15% next floor
# Invisible Cloak: one use ("1 hit", balancing.md). Documented ADR-018.
static var CLOAK_USES: int = 1
static var BLOOD_MODE_RESOURCE_FACTOR: float = 0.6  # ~40% rarer loot
static var BLOOD_MODE_DETECT_FACTOR: float = 1.5    # wider detection
static var BLOOD_MODE_ENERGY_FACTOR: float = 1.5    # faster fatigue
static var BLOOD_MODE_MONSTER_SPEED: float = 1.2    # faster monsters

# --- Generation (generation.md) ---
static var FLOOR_COUNT: int = 7
static var ROOMS_MIN: int = 12
static var ROOMS_MAX: int = 30
static var CHESTS_MIN: int = 3
static var CHESTS_MAX: int = 6
static var LOCKED_DOORS_MAX: int = 3
static var MONSTERS_MIN: int = 3
static var MONSTERS_MAX: int = 8

# --- Loot (generation.md §5; small:large ratio, documented ADR-018) ---
# 0.8 => 4:1 small:large oil bottles.
static var LOOT_OIL_SMALL_RATIO: float = 0.8

# --- Scene paths (flow) ---
const SCENE_MAIN_MENU: String = "res://scenes/MainMenu.tscn"
const SCENE_FLOOR_PLACEHOLDER: String = "res://scenes/FloorPlaceholder.tscn"
const SCENE_ENDING_PLACEHOLDER: String = "res://scenes/EndingPlaceholder.tscn"

# --- Save ---
const SAVE_VERSION: int = 1


func _init() -> void:
	_load_balancing()


func _load_balancing() -> void:
	if ResourceLoader.exists(BALANCING_PATH):
		balancing = load(BALANCING_PATH) as BalancingConfig
	if balancing == null:
		balancing = BalancingConfig.new()
	# Mirror resource values over the fallback defaults so gameplay code reads Config.X unchanged.
	PLAYER_MOVE_SPEED = balancing.player_move_speed
	PLAYER_RUN_SPEED = balancing.player_run_speed
	PLAYER_CROUCH_SPEED = balancing.player_crouch_speed
	PLAYER_MAX_HEALTH = balancing.player_max_health
	PLAYER_MAX_ENERGY = balancing.player_max_energy
	ENERGY_COST_WALK = balancing.energy_cost_walk
	ENERGY_COST_RUN = balancing.energy_cost_run
	ENERGY_REGEN_PER_MIN = balancing.energy_regen_per_min
	LANTERN_OIL_START = balancing.lantern_oil_start
	OIL_SMALL_REFILL = balancing.oil_small_refill
	OIL_LARGE_REFILL = balancing.oil_large_refill
	LAMP_OFF_DETECTION_FACTOR = balancing.lamp_off_detection_factor
	LANTERN_RADIUS_TILES = balancing.lantern_radius_tiles
	AMBIENT_DARKNESS = balancing.ambient_darkness
	LANTERN_COLOR = balancing.lantern_color
	MONSTER_PATROL_SPEED = balancing.monster_patrol_speed
	MONSTER_CHASE_SPEED = balancing.monster_chase_speed
	MONSTER_DETECTION_TILES = balancing.monster_detection_tiles
	MONSTER_CHASE_TILES = balancing.monster_chase_tiles
	MONSTER_VISION_ANGLE_DEG = balancing.monster_vision_angle_deg
	MONSTER_HEARING_TILES = balancing.monster_hearing_tiles
	MONSTER_AI_RANGE_TILES = balancing.monster_ai_range_tiles
	MONSTER_ROAM_PAUSE_MIN = balancing.monster_roam_pause_min
	MONSTER_ROAM_PAUSE_MAX = balancing.monster_roam_pause_max
	MONSTER_SEARCH_TIME = balancing.monster_search_time
	FOOD_APPLE_ENERGY = balancing.food_apple_energy
	FOOD_COOKIE_ENERGY = balancing.food_cookie_energy
	FOOD_CHEESE_ENERGY = balancing.food_cheese_energy
	FOOD_PIE_ENERGY = balancing.food_pie_energy
	NIGHT_VISION_DURATION = balancing.night_vision_duration
	SLEEP_MONSTER_WEAKEN = balancing.sleep_monster_weaken
	CLOAK_USES = balancing.cloak_uses
	BLOOD_MODE_RESOURCE_FACTOR = balancing.blood_mode_resource_factor
	BLOOD_MODE_DETECT_FACTOR = balancing.blood_mode_detect_factor
	BLOOD_MODE_ENERGY_FACTOR = balancing.blood_mode_energy_factor
	BLOOD_MODE_MONSTER_SPEED = balancing.blood_mode_monster_speed
	FLOOR_COUNT = balancing.floor_count
	ROOMS_MIN = balancing.rooms_min
	ROOMS_MAX = balancing.rooms_max
	CHESTS_MIN = balancing.chests_min
	CHESTS_MAX = balancing.chests_max
	LOCKED_DOORS_MAX = balancing.locked_doors_max
	MONSTERS_MIN = balancing.monsters_min
	MONSTERS_MAX = balancing.monsters_max
	LOOT_OIL_SMALL_RATIO = balancing.loot_oil_small_ratio


func _ready() -> void:
	if ProjectSettings.has_setting("pixel_horror/tile_size"):
		TILE_SIZE = ProjectSettings.get_setting("pixel_horror/tile_size")


func tiles_to_px(tiles: float) -> float:
	return tiles * float(TILE_SIZE)
