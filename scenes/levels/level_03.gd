extends Node2D


const TILE_SIZE := 48
const LEVEL_TILES := 52
const BOUNDS := Rect2i(0, 0, LEVEL_TILES * TILE_SIZE, 700)
const START_POSITION := Vector2(120.0, 448.0)

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const WALKER_SCENE := preload("res://scenes/enemies/walker.tscn")
const PATROLLER_SCENE := preload("res://scenes/enemies/ledge_patroller.tscn")
const BRUISER_SCENE := preload("res://scenes/enemies/bruiser.tscn")
const SHIELD_SCENE := preload("res://scenes/gameplay/shield_pickup.tscn")
const MOVING_PLATFORM_SCENE := preload("res://scenes/gameplay/moving_platform.tscn")
const FALLING_SPIKE_SCENE := preload("res://scenes/gameplay/falling_spike.tscn")
const SPIKE_SCENE := preload("res://scenes/gameplay/spike_hazard.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/gameplay/checkpoint.tscn")
const EXIT_SCENE := preload("res://scenes/gameplay/level_exit.tscn")
const COLLECTIBLE_SCENE := preload("res://scenes/gameplay/collectible.tscn")
const UI_SCENE := preload("res://scenes/ui/gameplay_ui.tscn")

var _ground_layer: TileMapLayer
var _one_way_layer: TileMapLayer


func _ready() -> void:
	InputSetup.ensure_default_actions()
	GameState.ensure_level_context(&"level_03")
	_build_tile_layers()
	_build_world()
	_build_gameplay()
	add_child(UI_SCENE.instantiate())
	GameState.register_level_spawn(START_POSITION, 12)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, float(LEVEL_TILES * TILE_SIZE), 700.0), Color("101827"), true)
	draw_rect(Rect2(0.0, 250.0, float(LEVEL_TILES * TILE_SIZE), 450.0), Color("252f3d"), true)
	for index in 20:
		var x := float(index * 137 + 55)
		var y := 90.0 + float((index * 61) % 260)
		draw_circle(Vector2(x, y), 38.0, Color(0.12, 0.62, 0.92, 0.055))
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, y - 26.0), Vector2(x + 12.0, y),
			Vector2(x, y + 30.0), Vector2(x - 12.0, y),
		]), Color(0.20, 0.72, 1.0, 0.52))


func _build_tile_layers() -> void:
	_ground_layer = _create_tile_layer("Ground", Color("384452"), false)
	_one_way_layer = _create_tile_layer("OneWayPlatforms", Color("416f86"), true)
	var decoration := TileMapLayer.new()
	decoration.name = "Decoration"
	decoration.collision_enabled = false
	add_child(decoration)

	# Intro and gauntlet floor, moving-platform gap, then the finale's safe exit floor.
	for x in LEVEL_TILES:
		if x < 24 or x >= 46:
			_ground_layer.set_cell(Vector2i(x, 10), 0, Vector2i.ZERO)
			_ground_layer.set_cell(Vector2i(x, 11), 0, Vector2i.ZERO)
	_paint_platform(5, 8, 4)
	_paint_platform(10, 7, 4)
	_paint_platform(16, 8, 3)
	_paint_platform(20, 7, 3)
	# Three staggered ledges descend across the spike-filled finale.
	_paint_platform(37, 5, 3)
	_paint_platform(40, 7, 3)
	_paint_platform(43, 9, 3)


func _create_tile_layer(layer_name: String, color: Color, one_way: bool) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1 << 0)
	var image := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(color)
	for x in TILE_SIZE:
		for y in 7:
			image.set_pixel(x, y, color.lightened(0.18))
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_source(source, 0)
	source.create_tile(Vector2i.ZERO)
	var tile_data := source.get_tile_data(Vector2i.ZERO, 0)
	tile_data.add_collision_polygon(0)
	tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-24.0, -24.0), Vector2(24.0, -24.0),
		Vector2(24.0, -17.0 if one_way else 24.0), Vector2(-24.0, -17.0 if one_way else 24.0),
	]))
	if one_way:
		tile_data.set_collision_polygon_one_way(0, 0, true)
		tile_data.set_collision_polygon_one_way_margin(0, 0, 5.0)
	layer.tile_set = tile_set
	add_child(layer)
	return layer


func _paint_platform(start_x: int, y: int, length: int) -> void:
	for x in range(start_x, start_x + length):
		_one_way_layer.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)


func _build_world() -> void:
	_add_world_block(Vector2(24.0, 300.0), Vector2(48.0, 600.0))
	_add_world_block(Vector2(float(LEVEL_TILES * TILE_SIZE) - 24.0, 300.0), Vector2(48.0, 600.0))
	var death_zone := DeathZone.new()
	death_zone.name = "KillPlane"
	death_zone.zone_size = Vector2(float(LEVEL_TILES * TILE_SIZE + 400), 180.0)
	death_zone.position = Vector2(float(LEVEL_TILES * TILE_SIZE) * 0.5, 720.0)
	add_child(death_zone)


func _build_gameplay() -> void:
	var player := PLAYER_SCENE.instantiate() as PocketPlayer
	player.name = "Player"
	player.position = START_POSITION
	add_child(player)
	player.apply_camera_bounds(BOUNDS)

	# Gift, safety-net, and finale shields: exactly three.
	_add_shield(Vector2(300.0, 430.0))
	_add_shield(Vector2(950.0, 330.0))
	_add_shield(Vector2(1800.0, 190.0))

	_add_enemy(WALKER_SCENE, Vector2(500.0, 430.0))
	_add_enemy(PATROLLER_SCENE, Vector2(750.0, 430.0))
	_add_enemy(WALKER_SCENE, Vector2(1060.0, 430.0))
	_add_enemy(BRUISER_SCENE, Vector2(2110.0, 405.0))

	var bridge := MOVING_PLATFORM_SCENE.instantiate() as PocketMovingPlatform
	bridge.position = Vector2(1200.0, 380.0)
	bridge.motion_vector = Vector2(200.0, 0.0)
	bridge.travel_time = 2.7
	add_child(bridge)

	var falling_spike := FALLING_SPIKE_SCENE.instantiate() as FallingSpike
	falling_spike.position = Vector2(1300.0, 95.0)
	add_child(falling_spike)

	_add_spike(Vector2(1950.0, 520.0), Vector2(300.0, 32.0))
	_add_spike(Vector2(2190.0, 520.0), Vector2(180.0, 32.0))

	var checkpoint := CHECKPOINT_SCENE.instantiate() as PocketCheckpoint
	checkpoint.checkpoint_id = &"aegis_descent"
	checkpoint.position = Vector2(1770.0, 220.0)
	add_child(checkpoint)

	var exit := EXIT_SCENE.instantiate() as PocketLevelExit
	exit.position = Vector2(2300.0, 480.0)
	add_child(exit)

	var seeds := [
		Vector2(390.0, 350.0), Vector2(650.0, 320.0), Vector2(850.0, 280.0),
		Vector2(1040.0, 310.0), Vector2(1200.0, 300.0), Vector2(1300.0, 250.0),
		Vector2(1400.0, 300.0), Vector2(1650.0, 300.0), Vector2(1810.0, 130.0),
		Vector2(1950.0, 250.0), Vector2(2100.0, 345.0), Vector2(2300.0, 380.0),
	]
	for index in seeds.size():
		var seed := COLLECTIBLE_SCENE.instantiate() as StarSeed
		seed.collectible_id = StringName("seed_%02d" % (index + 1))
		seed.position = seeds[index]
		add_child(seed)


func _add_world_block(at_position: Vector2, size: Vector2) -> void:
	var block := WorldBlock.new()
	block.position = at_position
	block.block_size = size
	block.block_color = Color("2a3544")
	add_child(block)


func _add_enemy(scene: PackedScene, at_position: Vector2) -> void:
	var enemy := scene.instantiate() as PocketEnemy
	enemy.position = at_position
	add_child(enemy)


func _add_shield(at_position: Vector2) -> void:
	var shield := SHIELD_SCENE.instantiate() as ShieldPickup
	shield.position = at_position
	add_child(shield)


func _add_spike(at_position: Vector2, size: Vector2) -> void:
	var spike := SPIKE_SCENE.instantiate() as SpikeHazard
	spike.position = at_position
	spike.hazard_size = size
	add_child(spike)
