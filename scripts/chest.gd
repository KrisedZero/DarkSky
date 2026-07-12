class_name Chest
extends BaseInteractable
## Loot chest. Holds a rolled loot table and, on first interact, deposits its contents into the
## inventory (coins via InventoryManager, items via ItemManager) and locks itself open.
## Chests are placed by LootPlacer (M14) per docs/generation.md §5. See docs/roadmap.md M14.

var chest_id: int = 0
var loot: Dictionary = {}  # StringName -> int (COIN handled specially)
var is_opened: bool = false

var _open_tex: Texture2D = load("res://assets/sprites/chest_open.png")

@onready var _sprite: Sprite2D = $Sprite


func _on_ready() -> void:
	prompt_text = "Open"


func interact(_interactor: Node) -> void:
	if is_opened:
		return
	is_opened = true
	interactable_enabled = false
	_sprite.texture = _open_tex
	AudioManager.play_sfx(AudioManager.Sfx.PICKUP)
	for id in loot:
		var amount: int = int(loot[id])
		if id == ItemsData.COIN:
			InventoryManager.add_coins(amount)
		elif ItemsData.is_artifact(id):
			InventoryManager.add_artifact(id)
			if id == ItemsData.CODEX_BLOOD:
				SignalBus.blood_mode_toggled.emit(true)
		else:
			ItemManager.pickup(id, amount)
	SignalBus.chest_opened.emit(chest_id)


## Snapshot for save (M16): which chest ids are opened is tracked by the save layer.
func snapshot() -> Dictionary:
	return {"id": chest_id, "loot": loot, "opened": is_opened}
