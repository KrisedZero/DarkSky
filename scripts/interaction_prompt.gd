extends Label
## Floating prompt that shows the focused interactable's text (e.g. "Hide").
## Listens to SignalBus.interaction_focus_changed. Pure UI; no game logic. See docs/roadmap.md M8.


func _ready() -> void:
	hide()
	SignalBus.interaction_focus_changed.connect(_on_focus_changed)


func _on_focus_changed(target: Node) -> void:
	if target == null:
		hide()
		return
	var interactable := target as BaseInteractable
	if interactable != null:
		text = "[E] " + interactable.prompt_text
		show()
