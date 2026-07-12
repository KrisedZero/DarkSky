extends Node2D
## Placeholder ending for M3 flow testing. Real roof/credits scene arrives in M23.


func _process(_delta: float) -> void:
	if InputReader.ui_confirmed():
		GameManager.return_to_menu()
