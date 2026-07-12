class_name BalancingConfig
extends Resource
## Data-driven balancing configuration (M27).
##
## This Resource is the single editable source of truth for all gameplay tunables.
## The default instance lives at `res://config/balancing.tres`; the `Config` autoload
## loads it at boot and mirrors the values into its own static fields, so gameplay code
## keeps calling `Config.X` unchanged. To rebalance the game, edit the `.tres` — no
## gameplay code needs to change.
##
## Keep the literal defaults below in sync with `res://config/balancing.tres`; they act
## as fallbacks only (used if the `.tres` is missing). Values are sourced from
## docs/balancing.md and the resolved conflicts in docs/conflicts-log.md / docs/decisions.md.
##
## See docs/roadmap.md M27.

# --- Player (balancing.md) ---
@export var player_move_speed: float = 120.0        # px/sec
@export var player_run_speed: float = 180.0         # px/sec
@export var player_crouch_speed: float = 80.0       # px/sec (hiding)
@export var player_max_health: int = 100            # unused (C5: no health); future use only
@export var player_max_energy: int = 100
@export var energy_cost_walk: float = 0.1           # % per sec
@export var energy_cost_run: float = 0.25           # % per sec
@export var energy_regen_per_min: float = 1.0       # % per min (minimal)

# --- Lantern (gameplay.md / balancing.md) ---
@export var lantern_oil_start: float = 600.0        # seconds (10 min)
@export var oil_small_refill: float = 60.0          # seconds
@export var oil_large_refill: float = 120.0         # seconds
# Lamp off reduces how easily the player is detected (design choice; see ADR-018).
@export var lamp_off_detection_factor: float = 0.5
# Max lantern radius in tiles (fills the 320x180 viewport at 32px). See ADR-018.
@export var lantern_radius_tiles: float = 5.0

# --- Lighting (art-style.md: warm light vs cool dark) ---
@export var ambient_darkness: Color = Color(0.08, 0.08, 0.12)
@export var lantern_color: Color = Color(1.0, 0.85, 0.55)  # warm orange

# --- Monster (balancing.md; sight radius conflict C3 resolved) ---
@export var monster_patrol_speed: float = 90.0      # px/sec
@export var monster_chase_speed: float = 140.0      # px/sec (< player run, ADR-013)
@export var monster_detection_tiles: float = 8.0
@export var monster_chase_tiles: float = 12.0
@export var monster_vision_angle_deg: float = 110.0
@export var monster_hearing_tiles: float = 4.0
# M26: idle monsters beyond this range skip detection (must exceed detection + hearing).
@export var monster_ai_range_tiles: float = 12.0
@export var monster_roam_pause_min: float = 1.0
@export var monster_roam_pause_max: float = 3.0
@export var monster_search_time: float = 5.0

# --- Food energy (balancing.md) ---
@export var food_apple_energy: int = 20
@export var food_cookie_energy: int = 10
@export var food_cheese_energy: int = 25
@export var food_pie_energy: int = 35

# --- Artifact effects (balancing.md; durations conflict C9 resolved, ADR-016) ---
@export var night_vision_duration: float = 120.0    # sec
@export var sleep_monster_weaken: float = 0.15      # 15% next floor
# Invisible Cloak: one use ("1 hit", balancing.md). See ADR-018.
@export var cloak_uses: int = 1
@export var blood_mode_resource_factor: float = 0.6 # ~40% rarer loot
@export var blood_mode_detect_factor: float = 1.5   # wider detection
@export var blood_mode_energy_factor: float = 1.5   # faster fatigue
@export var blood_mode_monster_speed: float = 1.2   # faster monsters

# --- Generation (generation.md) ---
@export var floor_count: int = 7
@export var rooms_min: int = 12
@export var rooms_max: int = 30
@export var chests_min: int = 3
@export var chests_max: int = 6
@export var locked_doors_max: int = 3
@export var monsters_min: int = 3
@export var monsters_max: int = 8

# --- Loot (generation.md §5; small:large ratio, see ADR-018) ---
# Probability an oil drop is the small bottle vs the large tank. 0.8 => 4:1 small:large.
@export var loot_oil_small_ratio: float = 0.8
