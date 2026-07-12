class_name Furniture
extends BaseInteractable
## Hiding furniture (wardrobe, chest, bed). Interacting toggles the player's hidden state,
## matching the stealth rule in docs/gameplay-summary.md §5. The actual monster visibility
## checks arrive in M18; here we only flip the player state and broadcast it.
## See docs/roadmap.md M8.

@export var is_bed: bool = false


func interact(interactor: Node) -> void:
	if interactor == null or not interactor.has_method("set_hidden"):
		return
	var controller := interactor as PlayerController
	var hidden := not controller.is_hidden()
	controller.set_hidden(hidden)
	AudioManager.play_sfx(AudioManager.Sfx.DOOR_OPEN if hidden else AudioManager.Sfx.DOOR_LOCK)
	if hidden:
		SignalBus.interact_requested.emit(self)
