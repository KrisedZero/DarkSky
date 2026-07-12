extends Node
## Scene transition manager (autoload "SceneLoader").
## Owns the "current scene" swap so callers never leak the previous scene tree.
## Provides an optional fade hook (visual fade added with the UI milestone).

var _current_scene: Node = null


func _ready() -> void:
	# Adopt whatever scene the engine booted into as the initial current scene.
	var tree := get_tree()
	_current_scene = tree.current_scene


## Replace the running scene with the scene at `path`. Frees the previous scene.
func change_scene(path: String) -> Node:
	var packed := load(path)
	if packed == null or not (packed is PackedScene):
		push_error("SceneLoader: cannot load scene at %s" % path)
		return null
	var instance := (packed as PackedScene).instantiate()
	_swap(instance)
	return instance


## Swap in an already-instantiated node as the current scene (useful for tests).
func change_to_instance(instance: Node) -> void:
	_swap(instance)


func get_current_scene() -> Node:
	return _current_scene


func _swap(instance: Node) -> void:
	var tree := get_tree()
	var root := tree.root
	# Fall back to the tree's current scene in case _ready ran before it was assigned.
	if _current_scene == null or not is_instance_valid(_current_scene):
		_current_scene = tree.current_scene
	if _current_scene != null and is_instance_valid(_current_scene):
		_current_scene.queue_free()
	root.add_child(instance)
	tree.current_scene = instance
	_current_scene = instance
