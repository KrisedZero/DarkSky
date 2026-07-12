extends Node
## Danger Sense (M21): when the player owns it, emits the direction toward the nearest monster each
## frame so the HUD can draw the red edge aura (docs/gameplay-summary.md §7, docs/items.md).
## The nearest-target helper is testable; the autoload drives it per frame.
## Visual feedback (red flash, vignette, aura) is the HUD's job (M22). Lighting reacts to the
## lamp and Blood Mode via LightingSystem (M7); M21 only adds the monster-direction signal.
##
## Stealth basis: lamp-off detection reduction lives in Monster.would_detect (M17); Danger Sense
## is the complementary player aid that reveals where the threat is.

const MONSTER_GROUP := "monster"
const PLAYER_GROUP := "player"

var _was_active: bool = false


func _process(_delta: float) -> void:
	var active := InventoryManager.get_flag(ItemsData.DANGER_SENSE)
	if not active:
		if _was_active:
			SignalBus.danger_sense_updated.emit(Vector2.ZERO)
			_was_active = false
		return
	_was_active = true
	var player := _find_player()
	if player == null:
		return
	var monsters := get_tree().get_nodes_in_group(MONSTER_GROUP)
	SignalBus.danger_sense_updated.emit(nearest_monster_direction(player.global_position, monsters))


## Direction (unit vector) from `origin` to the nearest valid monster; Vector2.ZERO if none.
static func nearest_monster_direction(origin: Vector2, monsters: Array) -> Vector2:
	var best_dist := INF
	var best_dir := Vector2.ZERO
	for m in monsters:
		if m == null or not is_instance_valid(m):
			continue
		var to: Vector2 = m.global_position - origin
		var d: float = to.length()
		if d < best_dist:
			best_dist = d
			best_dir = to
	if best_dir != Vector2.ZERO:
		best_dir = best_dir.normalized()
	return best_dir


func _find_player() -> Node:
	var nodes := get_tree().get_nodes_in_group(PLAYER_GROUP)
	if nodes.is_empty():
		return null
	return nodes[0]
