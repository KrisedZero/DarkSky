class_name KeyItem
extends BaseInteractable
## A key found on the floor (or in a chest) that adds a KEY to the inventory when taken.
## Placed by DoorPlacer (M15) on the entrance side of each locked door. See docs/roadmap.md M15.

var key_id: int = 0


func _on_ready() -> void:
	prompt_text = "Take Key"


func interact(_interactor: Node) -> void:
	if not interactable_enabled:
		return
	ItemManager.pickup(ItemsData.KEY, 1)
	AudioManager.play_sfx(AudioManager.Sfx.PICKUP)
	interactable_enabled = false
	SignalBus.interact_requested.emit(self)
