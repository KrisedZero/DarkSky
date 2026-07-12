extends Node
## Global event bus (autoload "SignalBus").
## Decouples gameplay, rendering, UI and audio: emitters emit here and
## any system connects without a direct reference. See docs/architecture.md.
##
## Signal catalog is authoritative. Add new signals here, not ad-hoc cross references.

# --- Game flow ---
signal game_started
signal game_over
signal game_won
signal game_paused
signal game_resumed
signal settings_opened
signal settings_closed
signal floor_changed(floor_index: int)
signal checkpoint_saved(floor_index: int)

# --- Player ---
signal player_spawned(player: Node)
signal player_caught
signal player_shield_consumed
signal player_state_changed(state: int)
signal lamp_toggled(is_on: bool)
signal lamp_oil_changed(seconds_remaining: float)
signal energy_changed(energy: float)

# --- Interaction ---
signal interact_requested(target: Node)
signal chest_opened(chest_id: int)
signal door_opened(door_id: int)
signal interaction_focus_changed(target: BaseInteractable)  # BaseInteractable or null
signal interaction_performed(target: Node)

# --- Inventory / items ---
signal inventory_changed
signal coins_changed(total: int)
signal artifact_acquired(artifact_id: String)

# --- Merchant ---
signal merchant_trade_opened(merchant: Node)

# --- Monster / stealth ---
signal monster_spotted_player(monster: Node)
signal monster_lost_player(monster: Node)
signal monster_state_changed(monster: Node, state: int)
signal heartbeat_triggered(intensity: float)
signal danger_sense_updated(direction: Vector2)

# --- Difficulty ---
signal blood_mode_toggled(active: bool)
signal achievement_unlocked(achievement_id: StringName)
