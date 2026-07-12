class_name Door
extends BaseInteractable
## Door between rooms/corridors (M15). Unlocked doors open on interact; locked doors require a KEY.
## M30: a closed door physically blocks movement (StaticBody2D) and marks its corridor tiles blocked
## in the WorldGrid so monsters route around / wait. See docs/roadmap.md M15, M30.

var door_id: int = 0
var is_locked: bool = false

var _world_grid: WorldGrid = null
var _is_open: bool = false

var world_grid: WorldGrid:
	set(v):
		_world_grid = v
		_apply_open_state()
	get:
		return _world_grid

var is_open: bool:
	set(v):
		_is_open = v
		_apply_open_state()
	get:
		return _is_open

const _open_tex := preload("res://assets/sprites/door_open.png")
const _closed_tex := preload("res://assets/sprites/door_closed.png")

@onready var _sprite: Sprite2D = $Sprite
@onready var _blocker: StaticBody2D = $Blocker


func _on_ready() -> void:
	_apply_open_state()
	_refresh_prompt()


func _refresh_prompt() -> void:
	if _is_open:
		prompt_text = "Open"
	elif is_locked:
		prompt_text = "Locked"
	else:
		prompt_text = "Open"


func interact(_interactor: Node) -> void:
	if _is_open:
		return
	if is_locked:
		if InventoryManager.count(ItemsData.KEY) < 1:
			return
		InventoryManager.remove_item(ItemsData.KEY, 1)
		is_locked = false
	is_open = true
	AudioManager.play_sfx(AudioManager.Sfx.DOOR_OPEN)
	SignalBus.door_opened.emit(door_id)


## Sync sprite, blocker, grid blocking and prompt to the current open/locked state.
func _apply_open_state() -> void:
	if _sprite != null:
		_sprite.texture = _open_tex if _is_open else _closed_tex
	if _blocker != null:
		_blocker.disabled = _is_open
	interactable_enabled = not _is_open
	_block_grid(not _is_open)
	_refresh_prompt()


## Mark the tiles covered by the physical blocker as blocked while closed, unblock when open.
func _block_grid(block: bool) -> void:
	if _world_grid == null:
		return
	var half := int(Config.TILE_SIZE * 0.5)
	var min_t := _world_grid.world_to_tile(global_position - Vector2(half, half))
	var max_t := _world_grid.world_to_tile(global_position + Vector2(half - 1, half - 1))
	for ty in range(min_t.y, max_t.y + 1):
		for tx in range(min_t.x, max_t.x + 1):
			var t := Vector2i(tx, ty)
			if _world_grid.is_floor_tile(t):
				_world_grid.set_blocked(t, block)


## Pure helper (unit-testable): would this door open for the given key count?
static func would_open(locked: bool, open: bool, keys: int) -> bool:
	if open:
		return false
	if locked:
		return keys >= 1
	return true
