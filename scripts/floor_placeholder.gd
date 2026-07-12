extends Node2D
## Floor scene. Builds a procedural floor from FloorLayout (M11) via FloorBuilder (M12) and shows
## live player state via the HUD (M22), driving floor transitions. Real art/entities arrive later.

var _layout: FloorLayout

@onready var _hud: HUD = $HUD
@onready var _camera: GameCamera = $Camera
@onready var _player: Node2D = $Player
@onready var _rooms: Node2D = $Rooms


func _ready() -> void:
	_build_floor()
	SignalBus.floor_changed.connect(_on_floor_changed)
	_refresh()


## Generate + instantiate the current floor from the run seed.
func _build_floor() -> void:
	var gen := FloorGenerator.new()
	_layout = gen.generate(
		GameManager.floor_seed(GameManager.current_floor), GameManager.current_floor
	)
	var fseed := GameManager.floor_seed(GameManager.current_floor)
	var mon_result := FloorBuilder.build(_layout, _rooms)
	var world_grid: WorldGrid = mon_result["world_grid"]
	FurniturePlacer.new().place(_layout, _rooms, fseed + 777)
	LootPlacer.new().place(_layout, _rooms, fseed + 131)
	DoorPlacer.new().place(_layout, _rooms, fseed + 151, world_grid)
	MonsterPlacer.new().place(_layout, _rooms, fseed + 191, world_grid)
	MerchantPlacer.new().place(_layout, _rooms, fseed + 211)
	_camera.set_bounds(mon_result["bounds_px"])
	_player.global_position = mon_result["entrance_px"]
	SaveManager.apply_opened_to_scene(self)


func _process(_delta: float) -> void:
	_refresh()
	if _player != null and is_instance_valid(_player) and _layout != null:
		var tile := (_player.global_position / Config.TILE_SIZE).floor()
		_player.on_balcony = _layout.is_balcony_at(tile)
	if InputReader.just_paused() and not GameManager._settings_open:
		GameManager.pause()
		return
	_cull_rooms()
	# ADR-015: only the stairs room ends the floor (a bare confirm anywhere is not enough).
	if InputReader.ui_confirmed() and _layout.is_stairs_at(tile):
		GameManager.advance_floor()
	elif InputReader.ui_cancelled():
		GameManager.return_to_menu()


## M26: hide rooms/corridors outside the camera view to cut draw + visibility work on large floors.
## Purely visual (toggles CanvasItem.visible); the player/HUD/lighting live elsewhere so are never culled.
func _cull_rooms() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var cam_rect := cam.get_viewport_rect()
	for child in _rooms.get_children():
		var r := child.get_global_rect()
		child.visible = Optimizer.rect_visible(r, cam_rect)


func _on_floor_changed(_index: int) -> void:
	_build_floor()
	_refresh()


func _refresh() -> void:
	if _hud != null:
		_hud.set_floor(GameManager.current_floor)
