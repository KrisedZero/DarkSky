class_name BaseEntity
extends CharacterBody2D
## Thin shared base for moving actors (Player, Monster).
## Keeps only what is genuinely common: an id and lifecycle hooks.
## No gameplay specifics live here (composition over inheritance, see docs/coding-style.md).

@export var entity_id: StringName = &""


func _ready() -> void:
	_on_spawn()


## Override in subclasses for spawn-time setup instead of overriding _ready directly.
func _on_spawn() -> void:
	pass
