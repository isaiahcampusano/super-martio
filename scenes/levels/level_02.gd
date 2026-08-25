extends Node2D


const TILE_SIZE := 48
const LEVEL_TILES := 84
const MAIN_BOUNDS := Rect2i(0, 0, LEVEL_TILES * TILE_SIZE, 540)
const CRYSTAL_BOUNDS := Rect2i(54 * TILE_SIZE, -540, 20 * TILE_SIZE, 540)
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
const POWERUP_SCENE := preload("res://scenes/gameplay/powerup.tscn")
const UI_SCENE := preload("res://scenes/ui/gameplay_ui.tscn")

var _player: PocketPlayer
var _ground_layer: TileMapLayer
var _one_way_layer: TileMapLayer


func _ready() -> void:
	InputSetup.ensure_default_actions()
	GameState.ensure_level_context(&"level_02")
	_build_tile_layers()
	_build_world_details()
	_build_gameplay()
	var ui := UI_SCENE.instantiate()
	add_child(ui)
	GameState.register_level_spawn(START_POSITION, 15)
	queue_redraw()


func _draw() -> void:
	# Layered stone silhouettes make the route feel enclosed rather than sky-lit.
	draw_rect(Rect2(0.0, -540.0, float(LEVEL_TILES * TILE_SIZE), 1080.0), Color("111824"), true)
	draw_rect(Rect2(0.0, 110.0, float(LEVEL_TILES * TILE_SIZE), 430.0), Color("202b39"), true)
	for index in 30:
		var x := float(index * 154 + 20)
		var ceiling_depth := 70.0 + float((index * 53) % 135)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 110.0, 0.0), Vector2(x, ceiling_depth), Vector2(x + 110.0, 0.0),
		]), Color("182330"))
	for index in 24:
		var glow_x := float(index * 181 + 95)
		var glow_y := 170.0 + float((index * 41) % 230)
		draw_circle(Vector2(glow_x, glow_y), 34.0 + float(index % 3) * 10.0, Color(0.95, 0.61, 0.20, 0.045))
		draw_colored_polygon(PackedVector2Array([
			Vector2(glow_x, glow_y - 18.0), Vector2(glow_x + 9.0, glow_y),
			Vector2(glow_x, glow_y + 22.0), Vector2(glow_x - 9.0, glow_y),
		]), Color(0.96, 0.65, 0.25, 0.55))

	# The optional chamber is brighter, denser, and framed by giant amber crystals.
	draw_rect(Rect2(float(CRYSTAL_BOUNDS.position.x), -540.0, float(CRYSTAL_BOUNDS.size.x), 540.0), Color("161c2b"), true)
	for index in 12:
		var crystal_x := float(CRYSTAL_BOUNDS.position.x + 42 + (index * 127) % CRYSTAL_BOUNDS.size.x)
		var crystal_height := 44.0 + float((index * 29) % 92)
		draw_colored_polygon(PackedVector2Array([
			Vector2(crystal_x - 17.0, -4.0), Vector2(crystal_x, -4.0 - crystal_height),
			Vector2(crystal_x + 17.0, -4.0),
		]), Color(0.98, 0.63, 0.18, 0.72))
		draw_circle(Vector2(crystal_x, -34.0 - crystal_height), 25.0, Color(1.0, 0.69, 0.25, 0.08))


func _build_tile_layers() -> void:
	_ground_layer = _create_tile_layer("Ground", Color("343b46"), false)
	_one_way_layer = _create_tile_layer("OneWayPlatforms", Color("596a78"), true)
	var decoration := TileMapLayer.new()
	decoration.name = "Decoration"
	decoration.collision_enabled = false
	add_child(decoration)

	# Every main-route gap is four tiles or narrower; moving platforms make the two
	# widest crossings forgiving without being mandatory.
	var main_gaps := {15: true, 16: true, 17: true, 31: true, 32: true, 33: true, 34: true, 52: true, 53: true, 54: true, 70: true, 71: true, 72: true, 73: true}
	for x in LEVEL_TILES:
		if not main_gaps.has(x):
			_ground_layer.set_cell(Vector2i(x, 10), 0, Vector2i.ZERO)
			_ground_layer.set_cell(Vector2i(x, 11), 0, Vector2i.ZERO)

	_paint_platform(_one_way_layer, 5, 8, 4)
	_paint_platform(_one_way_layer, 10, 7, 4)
	_paint_platform(_one_way_layer, 19, 8, 4)
	_paint_platform(_one_way_layer, 24, 7, 4)
	_paint_platform(_one_way_layer, 28, 5, 3)
	_paint_platform(_one_way_layer, 36, 8, 4)
	_paint_platform(_one_way_layer, 41, 7, 4)
	_paint_platform(_one_way_layer, 47, 8, 4)
	_paint_platform(_one_way_layer, 56, 7, 4)
	_paint_platform(_one_way_layer, 61, 5, 3)
	_paint_platform(_one_way_layer, 65, 8, 4)
	_paint_platform(_one_way_layer, 75, 7, 5)

	# Crystal chamber: a sealed camera zone above the main tunnel.
	for x in range(54, 75):
		_ground_layer.set_cell(Vector2i(x, -1), 0, Vector2i.ZERO)
	for y in range(-10, 0):
		_ground_layer.set_cell(Vector2i(54, y), 0, Vector2i.ZERO)
		_ground_layer.set_cell(Vector2i(74, y), 0, Vector2i.ZERO)
	_paint_platform(_one_way_layer, 57, -3, 3)
	_paint_platform(_one_way_layer, 62, -5, 3)
	_paint_platform(_one_way_layer, 67, -7, 3)


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
			image.set_pixel(x, y, color.lightened(0.16))
	for x in range(6, TILE_SIZE, 13):
		for y in range(12, TILE_SIZE, 11):
			image.set_pixel(x, y, color.darkened(0.26))
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
	_add_world_block(Vector2(24.0, 240.0), Vector2(48.0, 480.0), Color("292f3a"))
	_add_world_block(Vector2(float(LEVEL_TILES * TILE_SIZE) - 24.0, 240.0), Vector2(48.0, 480.0), Color("292f3a"))

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

	_add_spike(Vector2(665.0, 465.0), Vector2(72.0, 30.0))
	_add_spike(Vector2(2115.0, 465.0), Vector2(96.0, 30.0))
	_add_spike(Vector2(3135.0, 465.0), Vector2(72.0, 30.0))
	_add_spike(Vector2(3740.0, 465.0), Vector2(72.0, 30.0))

	_add_enemy(WALKER_SCENE, Vector2(470.0, 430.0))
	_add_enemy(PATROLLER_SCENE, Vector2(1015.0, 340.0))
	_add_enemy(BRUISER_SCENE, Vector2(1295.0, 420.0))
	_add_enemy(PATROLLER_SCENE, Vector2(1815.0, 390.0))
	_add_enemy(BRUISER_SCENE, Vector2(2300.0, 420.0))
	_add_enemy(WALKER_SCENE, Vector2(2810.0, 430.0))
	_add_enemy(PATROLLER_SCENE, Vector2(3190.0, 390.0))
	_add_enemy(BRUISER_SCENE, Vector2(3650.0, 420.0))

	_add_breakable(Vector2(960.0, 312.0))
	_add_breakable(Vector2(1008.0, 312.0))
	_add_breakable(Vector2(1968.0, 360.0))
	_add_breakable(Vector2(2928.0, 216.0))

	var bridge_platform := MOVING_PLATFORM_SCENE.instantiate() as PocketMovingPlatform
	bridge_platform.position = Vector2(1515.0, 414.0)
	bridge_platform.motion_vector = Vector2(150.0, -36.0)
	bridge_platform.travel_time = 2.8
	add_child(bridge_platform)

	var lift_platform := MOVING_PLATFORM_SCENE.instantiate() as PocketMovingPlatform
	lift_platform.position = Vector2(3425.0, 420.0)
	lift_platform.motion_vector = Vector2(0.0, -145.0)
	lift_platform.travel_time = 2.6
	lift_platform.phase_offset = PI * 0.45
	add_child(lift_platform)

	var checkpoint := CHECKPOINT_SCENE.instantiate() as PocketCheckpoint
	checkpoint.checkpoint_id = &"vault_lantern"
	checkpoint.position = Vector2(2050.0, 480.0)
	add_child(checkpoint)

	var entrance := WARP_SCENE.instantiate() as PocketWarpZone
	entrance.position = Vector2(1335.0, 480.0)
	entrance.target_position = Vector2(2685.0, -74.0)
	entrance.target_camera_bounds = CRYSTAL_BOUNDS
	entrance.accent_color = Color("e8a63a")
	add_child(entrance)

	var return_warp := WARP_SCENE.instantiate() as PocketWarpZone
	return_warp.position = Vector2(3440.0, -48.0)
	return_warp.target_position = Vector2(1410.0, 448.0)
	return_warp.target_camera_bounds = MAIN_BOUNDS
	return_warp.accent_color = Color("8099ad")
	add_child(return_warp)

	# Both extra lives sit off the critical path: one atop the main-route climb and
	# one at the far end of the optional crystal chamber.
	_add_powerup(Vector2(3024.0, 215.0))
	_add_powerup(Vector2(3264.0, -350.0))

	var exit := EXIT_SCENE.instantiate() as PocketLevelExit
	exit.position = Vector2(3945.0, 480.0)
	add_child(exit)

	var seed_positions := [
		Vector2(340.0, 345.0), Vector2(610.0, 415.0), Vector2(820.0, 315.0),
		Vector2(1100.0, 285.0), Vector2(1430.0, 415.0), Vector2(1600.0, 325.0),
		Vector2(1900.0, 300.0), Vector2(2210.0, 415.0), Vector2(2500.0, 315.0),
		Vector2(2780.0, 205.0), Vector2(3100.0, 315.0), Vector2(3490.0, 260.0),
		Vector2(3810.0, 300.0), Vector2(2880.0, -190.0), Vector2(3150.0, -300.0),
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


func _add_powerup(at_position: Vector2) -> void:
	var powerup := POWERUP_SCENE.instantiate() as PocketPowerup
	powerup.position = at_position
	add_child(powerup)
