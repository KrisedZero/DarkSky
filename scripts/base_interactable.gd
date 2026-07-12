class_name BaseInteractable
extends Area2D
## Shared contract for things the player can interact with (chests, doors, furniture).
## The InteractionController (M8) discovers these by group and calls interact().
## Aligns with the Room node contract in docs/world.md.

const GROUP: StringName = &"interactable"

@export var prompt_text: String = "Interact"
@export var interactable_enabled: bool = true


func _ready() -> void:
	add_to_group(GROUP)
	_on_ready()


## Override for setup instead of overriding _ready directly.
func _on_ready() -> void:
	pass


## Whether this object currently accepts interaction.
func can_interact(_interactor: Node) -> bool:
	return interactable_enabled


## Perform the interaction. Override in subclasses.
func interact(_interactor: Node) -> void:
	pass
