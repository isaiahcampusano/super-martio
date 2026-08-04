extends Node2D


const TILE_SIZE := 48
const LEVEL_TILES := 90
const MAIN_BOUNDS := Rect2i(0, 0, LEVEL_TILES * TILE_SIZE, 540)
const HIDDEN_BOUNDS := Rect2i(52 * TILE_SIZE, -540, 20 * TILE_SIZE, 540)
const START_POSITION := Vector2(120.0, 448.0)

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const WALKER_SCENE := preload("res://scenes/enemies/walker.tscn")
const PATROLLER_SCENE := preload("res://scenes/enemies/ledge_patroller.tscn")
const BRUISER_SCENE := preload("res://scenes/enemies/bruiser.tscn")
const COLLECTIBLE_SCENE := preload("res://scenes/gameplay/collectible.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/gameplay/checkpoint.tscn")
const EXIT_SCENE := preload("res://scenes/gameplay/level_exit.tscn")
const BREAKABLE_SCENE := preload("res://scenes/gameplay/breakable_block.tscn")
const MOVING_PLATFORM_SCENE := preload("res://scenes/gameplay/moving_platform.tscn")
const SPIKE_SCENE := preload("res://scenes/gameplay/spike_hazard.tscn")
const WARP_SCENE := preload("res://scenes/gameplay/warp_zone.tscn")
const UI_SCENE := preload("res://scenes/ui/gameplay_ui.tscn")

var _player: PocketPlayer
var _ground_layer: TileMapLayer
var _one_way_layer: TileMapLayer


func _ready() -> void:
	InputSetup.ensure_default_actions()
	GameState.ensure_level_context(&"level_01")
	_build_tile_layers()
	_build_world_details()
	_build_gameplay()
	var ui := UI_SCENE.instantiate()
	add_child(ui)
	GameState.register_level_spawn(START_POSITION, 14)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0.0, -540.0, float(LEVEL_TILES * TILE_SIZE), 1080.0), Color("112342"), true)
	draw_rect(Rect2(0.0, 230.0, float(LEVEL_TILES * TILE_SIZE), 310.0), Color("163554"), true)
	for index in 36:
		var x := float(index * 132 + 35)
		var height := 72.0 + float((index * 47) % 110)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 120.0, 480.0), Vector2(x, 480.0 - height), Vector2(x + 120.0, 480.0),
		]), Color(0.10, 0.32, 0.34, 0.62))
	for index in 22:
		var x := float(index * 205 + 120)
		draw_circle(Vector2(x, 120.0 + float((index * 31) % 90)), 26.0 + float(index % 4) * 8.0, Color(0.45, 0.72, 0.78, 0.08))

	# The secret sky-room is visually distinct and entirely original.
	draw_rect(Rect2(float(HIDDEN_BOUNDS.position.x), -540.0, float(HIDDEN_BOUNDS.size.x), 540.0), Color("201b48"), true)
	for index in 16:
		var star_x := float(HIDDEN_BOUNDS.position.x + 30 + (index * 149) % HIDDEN_BOUNDS.size.x)
		var star_y := -500.0 + float((index * 67) % 390)
		draw_circle(Vector2(star_x, star_y), 2.0 + float(index % 3), Color("f8e45c"))


func _build_tile_layers() -> void:
	_ground_layer = _create_tile_layer("Ground", Color("315a58"), false)
	_one_way_layer = _create_tile_layer("OneWayPlatforms", Color("4f8980"), true)
	var decoration := TileMapLayer.new()
	decoration.name = "Decoration"
	decoration.collision_enabled = false
	add_child(decoration)

	var main_gaps := {18: true, 19: true, 35: true, 36: true, 37: true, 38: true, 39: true, 59: true, 60: true, 61: true}
	for x in LEVEL_TILES:
		if not main_gaps.has(x):
			_ground_layer.set_cell(Vector2i(x, 10), 0, Vector2i.ZERO)
			_ground_layer.set_cell(Vector2i(x, 11), 0, Vector2i.ZERO)

	_paint_platform(_one_way_layer, 5, 8, 4)
	_paint_platform(_one_way_layer, 12, 7, 5)
	_paint_platform(_one_way_layer, 22, 8, 4)
	_paint_platform(_one_way_layer, 28, 7, 5)
	_paint_platform(_one_way_layer, 43, 8, 4)
	_paint_platform(_one_way_layer, 48, 6, 4)
	_paint_platform(_one_way_layer, 55, 7, 4)
	_paint_platform(_one_way_layer, 63, 8, 4)
	_paint_platform(_one_way_layer, 70, 7, 5)
	_paint_platform(_one_way_layer, 79, 8, 4)

	# Hidden room: a separate camera zone above the main trail.
	for x in range(52, 73):
		_ground_layer.set_cell(Vector2i(x, -1), 0, Vector2i.ZERO)
	for y in range(-10, 0):
		_ground_layer.set_cell(Vector2i(52, y), 0, Vector2i.ZERO)
		_ground_layer.set_cell(Vector2i(72, y), 0, Vector2i.ZERO)
	_paint_platform(_one_way_layer, 56, -4, 4)
	_paint_platform(_one_way_layer, 64, -6, 4)


func _create_tile_layer(layer_name: String, color: Color, one_way: bool) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1 << 0)
	tile_set.set_physics_layer_collision_mask(0, 0)

	var image := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(color)
	for x in TILE_SIZE:
		for y in 7:
			image.set_pixel(x, y, color.lightened(0.18))
	for x in range(0, TILE_SIZE, 12):
		for y in range(10, TILE_SIZE, 12):
			image.set_pixel(x, y, color.darkened(0.22))
	var texture := ImageTexture.create_from_image(image)
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_source(source, 0)
	source.create_tile(Vector2i.ZERO)
	var tile_data := source.get_tile_data(Vector2i.ZERO, 0)
	tile_data.add_collision_polygon(0)
	var top := -24.0
	var bottom := -17.0 if one_way else 24.0
	tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-24.0, top), Vector2(24.0, top), Vector2(24.0, bottom), Vector2(-24.0, bottom),
	]))
	if one_way:
		tile_data.set_collision_polygon_one_way(0, 0, true)
		tile_data.set_collision_polygon_one_way_margin(0, 0, 5.0)
	layer.tile_set = tile_set
	add_child(layer)
	return layer


func _paint_platform(layer: TileMapLayer, start_x: int, y: int, length: int) -> void:
	for x in range(start_x, start_x + length):
		layer.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)


func _build_world_details() -> void:
	_add_world_block(Vector2(24.0, 240.0), Vector2(48.0, 480.0), Color("254b51"))
	_add_world_block(Vector2(float(LEVEL_TILES * TILE_SIZE) - 24.0, 240.0), Vector2(48.0, 480.0), Color("254b51"))

	var death_zone := DeathZone.new()
	death_zone.name = "KillPlane"
	death_zone.zone_size = Vector2(float(LEVEL_TILES * TILE_SIZE + 400), 180.0)
	death_zone.position = Vector2(float(LEVEL_TILES * TILE_SIZE) * 0.5, 675.0)
	add_child(death_zone)


func _build_gameplay() -> void:
	_player = PLAYER_SCENE.instantiate() as PocketPlayer
	_player.name = "Player"
	_player.position = START_POSITION
	add_child(_player)
	_player.apply_camera_bounds(MAIN_BOUNDS)

	_add_spike(Vector2(790.0, 465.0), Vector2(96.0, 30.0))
	_add_spike(Vector2(2840.0, 465.0), Vector2(72.0, 30.0))
	_add_spike(Vector2(3970.0, 465.0), Vector2(72.0, 30.0))

	_add_enemy(WALKER_SCENE, Vector2(560.0, 430.0))
	_add_enemy(PATROLLER_SCENE, Vector2(1170.0, 410.0))
	_add_enemy(WALKER_SCENE, Vector2(1450.0, 430.0))
	_add_enemy(PATROLLER_SCENE, Vector2(2310.0, 410.0))
	_add_enemy(WALKER_SCENE, Vector2(3150.0, 430.0))
	_add_enemy(BRUISER_SCENE, Vector2(3690.0, 420.0))

	_add_breakable(Vector2(1056.0, 360.0))
	_add_breakable(Vector2(1104.0, 360.0))
	_add_breakable(Vector2(1536.0, 312.0))
	_add_breakable(Vector2(3456.0, 360.0))

	var moving_platform := MOVING_PLATFORM_SCENE.instantiate() as PocketMovingPlatform
	moving_platform.position = Vector2(1695.0, 395.0)
	moving_platform.motion_vector = Vector2(190.0, -50.0)
	moving_platform.travel_time = 3.1
	add_child(moving_platform)

	var vertical_platform := MOVING_PLATFORM_SCENE.instantiate() as PocketMovingPlatform
	vertical_platform.position = Vector2(2890.0, 420.0)
	vertical_platform.motion_vector = Vector2(0.0, -135.0)
	vertical_platform.travel_time = 2.8
	vertical_platform.phase_offset = PI * 0.35
	add_child(vertical_platform)

	var checkpoint := CHECKPOINT_SCENE.instantiate() as PocketCheckpoint
	checkpoint.checkpoint_id = &"meadow_rise"
	checkpoint.position = Vector2(2180.0, 480.0)
	add_child(checkpoint)

	var entrance := WARP_SCENE.instantiate() as PocketWarpZone
	entrance.position = Vector2(1555.0, 480.0)
	entrance.target_position = Vector2(2640.0, -74.0)
	entrance.target_camera_bounds = HIDDEN_BOUNDS
	entrance.accent_color = Color("7388ff")
	add_child(entrance)

	var return_warp := WARP_SCENE.instantiate() as PocketWarpZone
	return_warp.position = Vector2(3390.0, -48.0)
	return_warp.target_position = Vector2(1630.0, 448.0)
	return_warp.target_camera_bounds = MAIN_BOUNDS
	return_warp.accent_color = Color("66e6b4")
	add_child(return_warp)

	var exit := EXIT_SCENE.instantiate() as PocketLevelExit
	exit.position = Vector2(4180.0, 480.0)
	add_child(exit)

	var seed_positions := [
		Vector2(335.0, 350.0), Vector2(660.0, 300.0), Vector2(880.0, 420.0),
		Vector2(1285.0, 285.0), Vector2(1760.0, 290.0), Vector2(2030.0, 420.0),
		Vector2(2470.0, 300.0), Vector2(2780.0, 420.0), Vector2(3260.0, 320.0),
		Vector2(3810.0, 420.0), Vector2(2700.0, -150.0), Vector2(2920.0, -240.0),
		Vector2(3160.0, -340.0), Vector2(3320.0, -105.0),
	]
	for index in seed_positions.size():
		var seed := COLLECTIBLE_SCENE.instantiate() as StarSeed
		seed.collectible_id = StringName("seed_%02d" % (index + 1))
		seed.position = seed_positions[index]
		add_child(seed)


func _add_world_block(at_position: Vector2, size: Vector2, color: Color) -> void:
	var block := WorldBlock.new()
	block.position = at_position
	block.block_size = size
	block.block_color = color
	add_child(block)


func _add_enemy(scene: PackedScene, at_position: Vector2) -> void:
	var enemy := scene.instantiate() as PocketEnemy
	enemy.position = at_position
	add_child(enemy)


func _add_spike(at_position: Vector2, size: Vector2) -> void:
	var spike := SPIKE_SCENE.instantiate() as SpikeHazard
	spike.position = at_position
	spike.hazard_size = size
	add_child(spike)


func _add_breakable(at_position: Vector2) -> void:
	var block := BREAKABLE_SCENE.instantiate() as BreakableBlock
	block.position = at_position
	add_child(block)
