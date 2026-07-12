class_name HUD
extends CanvasLayer
## On-floor HUD (M22). Listens to SignalBus only — UI is kept separate from game logic
## (docs/architecture.md §7). Shows coins, lamp oil, energy, floor, artifacts, the Danger Sense
## edge aura (rotates toward the threat, pulses with heartbeat audio), a red detection flash with
## screen shake, and a heartbeat pulse — all wired in M28. Rendering is placeholder (Labels +
## ColorRects); real icon art remains a later art pass.
## See docs/roadmap.md M22/M28 and docs/gameplay-summary.md §11.

var coins: int = 0
var oil: float = 0.0
var energy: float = 0.0
var lamp_on: bool = true
var floor_index: int = 1
var danger_dir: Vector2 = Vector2.ZERO
var spotted: bool = false
var heartbeat: float = 0.0
var hidden: bool = false
var artifacts: Array[StringName] = []
var _heartbeat_cd: float = 0.0
var _danger_pulse: float = 0.0
var _flash_tween: Tween

@onready var _floor_label: Label = $TopLeft/Floor
@onready var _oil_label: Label = $TopLeft/Oil
@onready var _energy_label: Label = $TopLeft/Energy
@onready var _coins_label: Label = $TopRight/Coins
@onready var _status_label: Label = $TopRight/Status
@onready var _artifacts_label: Label = $Bottom/Artifacts
@onready var _danger: Control = $DangerAura
@onready var _flash: ColorRect = $Flash


func _ready() -> void:
	_connect()
	_sync_initial()
	if _danger != null:
		_danger.pivot_offset = _danger.size / 2.0
	_refresh()


## Pull current state from autoloads/player so the HUD is correct even if the player emitted its
## spawn signals before this node connected (children _ready before parent in Godot).
func _sync_initial() -> void:
	coins = InventoryManager.coins
	for a in InventoryManager.artifacts:
		if a not in artifacts:
			artifacts.append(a)
	var player := _find_player()
	if player != null and is_instance_valid(player):
		energy = player.energy
		oil = player.lamp_oil
		lamp_on = player.lamp_on
		hidden = player.is_hidden()


func _find_player() -> Node:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return null
	return nodes[0]


func _connect() -> void:
	SignalBus.coins_changed.connect(_on_coins)
	SignalBus.lamp_oil_changed.connect(_on_oil)
	SignalBus.energy_changed.connect(_on_energy)
	SignalBus.lamp_toggled.connect(_on_lamp)
	SignalBus.danger_sense_updated.connect(_on_danger)
	SignalBus.monster_spotted_player.connect(_on_spotted)
	SignalBus.monster_lost_player.connect(_on_lost)
	SignalBus.heartbeat_triggered.connect(_on_heartbeat)
	SignalBus.player_state_changed.connect(_on_state)
	SignalBus.artifact_acquired.connect(_on_artifact)


## Push the current floor number (driven by FloorPlaceholder on build/transition).
func set_floor(n: int) -> void:
	floor_index = n
	_refresh()


func _on_coins(total: int) -> void:
	coins = total
	_refresh()


func _on_oil(seconds: float) -> void:
	oil = seconds
	_refresh()


func _on_energy(value: float) -> void:
	energy = value
	_refresh()


func _on_lamp(on: bool) -> void:
	lamp_on = on
	_refresh()


func _on_danger(dir: Vector2) -> void:
	danger_dir = dir
	if _danger != null:
		_danger.visible = dir != Vector2.ZERO
		if dir != Vector2.ZERO:
			_danger.rotation = dir.angle()


func _on_spotted(_m: Node) -> void:
	spotted = true
	if _flash != null:
		if _flash_tween != null and _flash_tween.is_valid():
			_flash_tween.kill()
		_flash.visible = true
		_flash.modulate.a = 0.0
		_flash_tween = create_tween()
		_flash_tween.tween_property(_flash, "modulate:a", 0.5, 0.12)
		_flash_tween.tween_property(_flash, "modulate:a", 0.0, 0.5)
		_flash_tween.tween_callback(_hide_flash)
	ScreenShake.add_trauma(0.5)


func _on_lost(_m: Node) -> void:
	spotted = false
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_hide_flash()


func _hide_flash() -> void:
	if _flash != null:
		_flash.visible = false


func _on_heartbeat(intensity: float) -> void:
	heartbeat = intensity
	if intensity <= 0.0:
		return
	# Throttle so the sting doesn't machine-gun when the monster is close.
	if _heartbeat_cd <= 0.0:
		AudioManager.play_sfx(AudioManager.Sfx.HEARTBEAT)
		_heartbeat_cd = 0.7
	_danger_pulse = maxf(_danger_pulse, intensity)


func _process(delta: float) -> void:
	if _heartbeat_cd > 0.0:
		_heartbeat_cd -= delta
	# Decay the pulse and map it to the aura's alpha for a beating glow (M28).
	if _danger != null and _danger.visible:
		_danger_pulse = maxf(0.0, _danger_pulse - delta * 1.5)
		_danger.modulate.a = 0.55 + 0.4 * _danger_pulse


func _on_state(state: int) -> void:
	hidden = state == PlayerController.State.HIDDEN
	_refresh()


func _on_artifact(id: StringName) -> void:
	if id not in artifacts:
		artifacts.append(id)
	_refresh()


func _refresh() -> void:
	if _floor_label != null:
		_floor_label.text = "Floor %d" % floor_index
	if _oil_label != null:
		_oil_label.text = "Oil: %ds %s" % [int(oil), "ON" if lamp_on else "OFF"]
	if _energy_label != null:
		_energy_label.text = "Energy: %d" % int(energy)
	if _coins_label != null:
		_coins_label.text = "Coins: %d" % coins
	if _status_label != null:
		_status_label.text = "HIDDEN" if hidden else ""
	if _artifacts_label != null:
		_artifacts_label.text = "Artifacts: " + ", ".join(artifacts)
