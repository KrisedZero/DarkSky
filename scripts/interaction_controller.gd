extends Node
## Interaction dispatcher (autoload "InteractionController").
## Watches the player's interaction Area2D for nearby BaseInteractable nodes, picks the closest
## that currently accepts interaction, and dispatches interact() on the interact input edge.
## Emits focus/performed signals for the HUD. See docs/roadmap.md M8 and docs/architecture.md.

var _player_area: Area2D = null
var _player: Node = null
var _nearby: Array[BaseInteractable] = []
var _current: BaseInteractable = null


func _ready() -> void:
	SignalBus.player_spawned.connect(_on_player_spawned)


func _on_player_spawned(player: Node) -> void:
	_player = player


## Called by the player once its interaction Area2D exists.
func register_player_area(area: Area2D, player: Node) -> void:
	if not is_instance_valid(area):
		return
	if _player_area != null:
		_unregister_area()
	_player_area = area
	_player = player
	area.area_entered.connect(_on_area_entered)
	area.area_exited.connect(_on_area_exited)


func unregister_player_area() -> void:
	_unregister_area()
	_player = null


func _unregister_area() -> void:
	if _player_area == null:
		return
	if _player_area.is_connected("area_entered", _on_area_entered):
		_player_area.area_entered.disconnect(_on_area_entered)
	if _player_area.is_connected("area_exited", _on_area_exited):
		_player_area.area_exited.disconnect(_on_area_exited)
	_player_area = null
	_nearby.clear()
	_set_current(null)


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group(BaseInteractable.GROUP):
		return
	var target := area as BaseInteractable
	if target != null and not _nearby.has(target):
		_nearby.append(target)


func _on_area_exited(area: Area2D) -> void:
	var target := area as BaseInteractable
	if target != null:
		_nearby.erase(target)
		if _current == target:
			_set_current(null)


func _process(_delta: float) -> void:
	_refresh_focus()
	if _current != null and InputReader.just_interacted():
		_dispatch(_current)


func _refresh_focus() -> void:
	var best: BaseInteractable = null
	if is_instance_valid(_player):
		var origin := (_player as Node2D).global_position
		var best_dist := INF
		for candidate in _nearby:
			if not is_instance_valid(candidate):
				_nearby.erase(candidate)
				continue
			if not candidate.can_interact(_player):
				continue
			var d := origin.distance_to(candidate.global_position)
			if d < best_dist:
				best_dist = d
				best = candidate
	_set_current(best)


func _set_current(next: BaseInteractable) -> void:
	if next == _current:
		return
	_current = next
	SignalBus.interaction_focus_changed.emit(next)


func _dispatch(target: BaseInteractable) -> void:
	if not is_instance_valid(_player):
		return
	target.interact(_player)
	SignalBus.interaction_performed.emit(target)


## Pure helper (unit-testable): choose the closest interactable from a candidate list.
static func select_closest(origin: Vector2, candidates: Array, interactor: Node) -> Object:
	var best: Object = null
	var best_dist := INF
	for candidate in candidates:
		if not (candidate is BaseInteractable):
			continue
		if not candidate.can_interact(interactor):
			continue
		var d := origin.distance_to(candidate.global_position)
		if d < best_dist:
			best_dist = d
			best = candidate
	return best
