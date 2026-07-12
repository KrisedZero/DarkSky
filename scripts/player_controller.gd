class_name PlayerController
extends BaseEntity
## The boy the player controls. Handles top-down movement (walk/run), energy drain/regen,
## Normal/Hidden state, and the lantern (on/off + oil burn).
## No combat. Consumes intents from InputReader; broadcasts state via SignalBus.
## Interaction (hiding, using items) is driven externally in later milestones (M8+).

enum State { NORMAL, HIDDEN }

var state: int = State.NORMAL
var energy: float = float(Config.PLAYER_MAX_ENERGY)
var lamp_on: bool = true
var lamp_oil: float = Config.LANTERN_OIL_START
var on_balcony: bool = false  # M20: true while standing on a balcony (monster safe zone)

var _regen_per_sec: float = Config.ENERGY_REGEN_PER_MIN / 60.0


func _enter_tree() -> void:
	add_to_group("player")


func _on_spawn() -> void:
	add_to_group("player")
	SignalBus.player_spawned.emit(self)
	SignalBus.energy_changed.emit(energy)
	SignalBus.lamp_toggled.emit(lamp_on)
	SignalBus.lamp_oil_changed.emit(lamp_oil)
	var area := get_node_or_null("InteractionArea")
	if area is Area2D:
		InteractionController.register_player_area(area, self)


func _physics_process(delta: float) -> void:
	if InputReader.just_toggled_lamp():
		_toggle_lamp()
	_update_lamp(delta)
	_update_movement(delta)


# --- Movement & energy ---


func _update_movement(delta: float) -> void:
	if state == State.HIDDEN:
		velocity = Vector2.ZERO
		return
	var direction := InputReader.get_move_vector()
	var moving := direction != Vector2.ZERO
	var running := moving and InputReader.is_run_held() and energy > 0.0
	var speed := Config.PLAYER_RUN_SPEED if running else Config.PLAYER_MOVE_SPEED
	velocity = direction * speed
	move_and_slide()
	_update_energy(delta, moving, running)


func _update_energy(delta: float, moving: bool, running: bool) -> void:
	var previous := energy
	if moving:
		var cost := Config.ENERGY_COST_RUN if running else Config.ENERGY_COST_WALK
		if InventoryManager.has_artifact(ItemsData.CODEX_BLOOD):
			cost *= Config.BLOOD_MODE_ENERGY_FACTOR
		energy -= cost * delta
	else:
		energy += _regen_per_sec * delta
	energy = clampf(energy, 0.0, float(Config.PLAYER_MAX_ENERGY))
	if not is_equal_approx(energy, previous):
		SignalBus.energy_changed.emit(energy)


# --- State ---


func set_hidden(hidden: bool) -> void:
	var new_state := State.HIDDEN if hidden else State.NORMAL
	if new_state == state:
		return
	state = new_state
	SignalBus.player_state_changed.emit(state)


func is_hidden() -> bool:
	return state == State.HIDDEN


# --- Lantern ---


func _toggle_lamp() -> void:
	if lamp_oil <= 0.0:
		return
	lamp_on = not lamp_on
	AudioManager.play_sfx(AudioManager.Sfx.LANTERN_ON if lamp_on else AudioManager.Sfx.LANTERN_OFF)
	SignalBus.lamp_toggled.emit(lamp_on)


func _update_lamp(delta: float) -> void:
	if not lamp_on or lamp_oil <= 0.0:
		return
	lamp_oil = maxf(0.0, lamp_oil - delta)
	SignalBus.lamp_oil_changed.emit(lamp_oil)
	if lamp_oil <= 0.0:
		lamp_on = false
		SignalBus.lamp_toggled.emit(false)


## Refill lantern fuel (used by oil items in M10).
func add_oil(seconds: float) -> void:
	lamp_oil += seconds
	SignalBus.lamp_oil_changed.emit(lamp_oil)


## Restore energy (used by food items in M10).
func add_energy(amount: float) -> void:
	energy = clampf(energy + amount, 0.0, float(Config.PLAYER_MAX_ENERGY))
	SignalBus.energy_changed.emit(energy)
