extends CanvasLayer
## Game Over overlay (M28). Shown by GameManager.game_over(): a red fade-in + message plays the
## game-over sting, then after a short beat it returns to the main menu and frees itself.
## The overlay owns the return so the floor scene is not swapped until the player has seen the
## feedback (replacing the old immediate game_over -> return_to_menu connection).
## See docs/roadmap.md M28.

const RETURN_DELAY: float = 2.5

@onready var _flash: ColorRect = $Flash
@onready var _msg: Label = $Message


func _ready() -> void:
	visible = true
	_flash.modulate.a = 0.0
	_msg.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_flash, "modulate:a", 0.6, 0.6)
	t.parallel().tween_property(_msg, "modulate:a", 1.0, 0.6)
	await t.finished
	await get_tree().create_timer(RETURN_DELAY).timeout
	_return()


func _unhandled_input(_event: InputEvent) -> void:
	# Allow skipping the delay once the fade-in is visible.
	if visible and _flash.modulate.a > 0.3:
		_return()


func _return() -> void:
	if not is_instance_valid(self):
		return
	GameManager.return_to_menu()
	queue_free()
