extends Node


var _failures: Array[String] = []
var _respawn_position := Vector2.INF


func _ready() -> void:
	call_deferred(&"_run")


func _run() -> void:
	await get_tree().process_frame
	_test_catalog()
	_test_save_store()
	await _test_game_state()
	await _test_player_jump()
	await _test_shield_powerup()
	await _test_powerup_box()
	await _test_enemy_bonus()
	await _test_scenes()
	if _failures.is_empty():
		print("PASS: Pocket Platformer automated checks completed successfully.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("FAIL: %s" % failure)
	get_tree().quit(1)


func _test_catalog() -> void:
	_check(LevelCatalog.has_level(&"level_01"), "Level catalog should contain level_01")
	_check(LevelCatalog.has_level(&"level_02"), "Level catalog should contain level_02")
	_check(LevelCatalog.has_level(&"level_03"), "Level catalog should contain level_03")
	_check(LevelCatalog.get_scene_path(&"level_01") == "res://scenes/levels/level_01.tscn", "Level path should be stable")
	_check(LevelCatalog.get_scene_path(&"level_02") == "res://scenes/levels/level_02.tscn", "Level 2 path should be stable")
	_check(LevelCatalog.get_required_level(&"level_02") == &"level_01", "Level 2 should require level 1")
	_check(LevelCatalog.get_required_level(&"level_03") == &"level_02", "Level 3 should require level 2")
	_check(LevelCatalog.is_unlocked(&"level_03", PackedStringArray(["level_02"])), "Clearing level 2 should unlock level 3")
	_check(not LevelCatalog.is_unlocked(&"level_02", PackedStringArray()), "Level 2 should begin locked")
	_check(LevelCatalog.is_unlocked(&"level_02", PackedStringArray(["level_01"])), "Clearing level 1 should unlock level 2")
	_check(LevelCatalog.get_scene_path(&"missing").is_empty(), "Unknown level IDs should not resolve")


func _test_save_store() -> void:
	var path := "user://pocket_platformer_test_save.cfg"
	var store := SaveStore.new()
	store.save_path = path
	var completed := PackedStringArray(["level_01"])
	var save_error := store.save_progress(completed, {"level_01": 12.5}, {"level_01": 9})
	_check(save_error == OK, "SaveStore should write a valid ConfigFile")
	var loaded := store.load_progress()
	_check((loaded["completed_levels"] as PackedStringArray).has("level_01"), "SaveStore should restore completed level IDs")
	_check(is_equal_approx(float((loaded["best_times"] as Dictionary)["level_01"]), 12.5), "SaveStore should restore best times")
	_check(int((loaded["best_collectibles"] as Dictionary)["level_01"]) == 9, "SaveStore should restore collectible records")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _test_game_state() -> void:
	GameState.debug_begin_run(&"level_01")
	GameState.register_level_spawn(Vector2(20.0, 30.0), 5)
	_check(GameState.lives == 3, "A new run should start with three lives")
	_check(GameState.run_status == GameState.RunStatus.PLAYING, "Registering the spawn should start play")
	_check(GameState.collectible_total == 5, "The level should register its collectible total")
	_check(GameState.register_collectible(&"test_seed"), "A new collectible should be accepted")
	_check(not GameState.register_collectible(&"test_seed"), "A duplicate collectible should be rejected")
	GameState.activate_checkpoint(&"test_checkpoint", Vector2(80.0, 90.0))
	_check(GameState.spawn_position == Vector2(80.0, 90.0), "Checkpoint should update respawn position")
	if not GameState.respawn_requested.is_connected(_on_respawn_requested):
		GameState.respawn_requested.connect(_on_respawn_requested)
	GameState.request_player_death()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(GameState.lives == 2, "A death should remove exactly one life")
	_check(_respawn_position == Vector2(80.0, 90.0), "A non-final death should request the checkpoint position")
	GameState.confirm_respawn()
	_check(GameState.run_status == GameState.RunStatus.PLAYING, "Confirming respawn should resume play")


func _test_player_jump() -> void:
	GameState.debug_begin_run(&"level_01")
	GameState.register_level_spawn(Vector2.ZERO, 0)

	var arena := Node2D.new()
	var floor := StaticBody2D.new()
	floor.collision_layer = 1 << 0
	var floor_collision := CollisionShape2D.new()
	var floor_shape := RectangleShape2D.new()
	floor_shape.size = Vector2(640.0, 32.0)
	floor_collision.shape = floor_shape
	floor.add_child(floor_collision)
	floor.position = Vector2(0.0, 120.0)
	arena.add_child(floor)

	var player_scene := load("res://scenes/player/player.tscn") as PackedScene
	var player := player_scene.instantiate() as PocketPlayer
	player.position = Vector2(0.0, 60.0)
	arena.add_child(player)
	get_tree().root.add_child(arena)

	var settled := await _wait_for_floor(player)
	_check(settled, "Player should settle on the jump-test floor")
	if not settled:
		arena.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		return
	_check(player.animation_state == PocketPlayer.AnimationState.IDLE, "A grounded stationary player should use the idle animation")
	Input.action_press(&"crouch")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(player.animation_state == PocketPlayer.AnimationState.CROUCH, "Crouching should use the crouch animation")
	Input.action_release(&"crouch")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(player.animation_state == PocketPlayer.AnimationState.IDLE, "Releasing crouch should restore the idle animation")

	var grounded_y := player.global_position.y
	var apex_y := grounded_y
	var saw_rise_animation := false
	var saw_fall_animation := false
	Input.action_press(&"jump")
	for frame in 90:
		await get_tree().physics_frame
		apex_y = minf(apex_y, player.global_position.y)
		saw_rise_animation = saw_rise_animation or player.animation_state == PocketPlayer.AnimationState.RISE
		if not player.is_on_floor() and player.velocity.y >= 0.0:
			saw_fall_animation = player.animation_state == PocketPlayer.AnimationState.FALL
			break
	Input.action_release(&"jump")
	var full_jump_height := grounded_y - apex_y
	_check(full_jump_height >= 100.0, "A full jump should rise high enough to clear a two-tile step")
	_check(saw_rise_animation, "A rising player should use the rise animation")
	_check(saw_fall_animation, "A descending player should use the fall animation")
	_check(await _wait_for_floor(player), "Player should land after a full jump")
	_check(float(player.get(&"_landing_squash_remaining")) > 0.0, "Landing should activate the squash animation")

	var short_hop_grounded_y := player.global_position.y
	var short_hop_apex_y := short_hop_grounded_y
	Input.action_press(&"jump")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(&"jump")
	for frame in 90:
		await get_tree().physics_frame
		short_hop_apex_y = minf(short_hop_apex_y, player.global_position.y)
		if not player.is_on_floor() and player.velocity.y >= 0.0:
			break
	var short_hop_height := short_hop_grounded_y - short_hop_apex_y
	_check(short_hop_height >= 40.0, "A quick tap should still produce a noticeable short hop")
	_check(short_hop_height < full_jump_height - 20.0, "A quick tap should remain shorter than a held jump")
	_check(await _wait_for_floor(player), "Player should land after a short hop")

	Input.action_press(&"jump")
	for frame in 6:
		await get_tree().physics_frame
	Input.action_release(&"jump")
	await get_tree().physics_frame
	Input.action_press(&"jump")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(player.velocity.y < -450.0, "A second airborne press should launch an air jump (velocity: %.1f)" % player.velocity.y)
	_check(player.animation_state == PocketPlayer.AnimationState.RISE, "An air jump should return to the rise animation")
	_check(float(player.get(&"_air_jump_feedback_remaining")) > 0.0, "An air jump should activate its visual feedback")
	for frame in 4:
		await get_tree().physics_frame
	Input.action_release(&"jump")

	for frame in 90:
		await get_tree().physics_frame
		if not player.is_on_floor() and player.velocity.y > 60.0:
			break
	_check(not player.is_on_floor() and player.velocity.y > 60.0, "Player should be airborne before testing the jump limit")
	Input.action_press(&"jump")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(player.velocity.y > 0.0, "A third airborne press should not launch another jump (velocity: %.1f)" % player.velocity.y)
	Input.action_release(&"jump")
	_check(await _wait_for_floor(player), "Player should land after using the air jump")

	Input.action_press(&"jump")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(player.velocity.y < -450.0, "Landing should restore the normal jump (velocity: %.1f)" % player.velocity.y)
	Input.action_release(&"jump")
	arena.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _test_powerup_box() -> void:
	GameState.debug_begin_run(&"level_01")
	GameState.register_level_spawn(Vector2.ZERO, 0)
	var arena := Node2D.new()
	get_tree().root.add_child(arena)
	var block_scene := load("res://scenes/gameplay/breakable_block.tscn") as PackedScene
	var block := block_scene.instantiate() as BreakableBlock
	block.position = Vector2(0.0, 100.0)
	arena.add_child(block)
	await get_tree().physics_frame
	_check(block.collision_layer == 1 << 0, "A powerup box should use the solid-world collision layer")
	var shape := block.get_child(0) as CollisionShape2D
	_check(shape != null and not shape.disabled, "A fresh powerup box should have an enabled solid collision shape")
	var probe := CharacterBody2D.new()
	probe.collision_layer = 1 << 1
	probe.collision_mask = 1 << 0
	var probe_collision := CollisionShape2D.new()
	var probe_shape := RectangleShape2D.new()
	probe_shape.size = Vector2(16.0, 16.0)
	probe_collision.shape = probe_shape
	probe.add_child(probe_collision)
	arena.add_child(probe)
	await get_tree().physics_frame
	probe.position = Vector2(0.0, 40.0)
	_check(probe.move_and_collide(Vector2(0.0, 80.0)) != null, "A player body should land on top of a powerup box")
	probe.position = Vector2(-60.0, 100.0)
	_check(probe.move_and_collide(Vector2(100.0, 0.0)) != null, "A powerup box should block horizontal movement")
	probe.position = Vector2(0.0, 160.0)
	_check(probe.move_and_collide(Vector2(0.0, -100.0)) != null, "A powerup box should block movement from below")

	block.hit_from_below()
	await get_tree().process_frame
	_check(block.used, "A box hit from below should enter its used state")
	_check(shape != null and not shape.disabled, "A used box should remain solid")
	var powerups := arena.find_children("*", "PocketPowerup", true, false)
	_check(powerups.size() == 1, "The first hit should spawn exactly one powerup")
	block.hit_from_below()
	await get_tree().process_frame
	powerups = arena.find_children("*", "PocketPowerup", true, false)
	_check(powerups.size() == 1, "A used box should not spawn another powerup")
	if powerups.size() == 1:
		probe.add_to_group(&"player")
		var lives_before := GameState.lives
		(powerups[0] as PocketPowerup)._on_body_entered(probe)
		_check(GameState.lives == lives_before + 1, "Collecting the spawned Star Sprout should grant one life")
	arena.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _test_shield_powerup() -> void:
	GameState.debug_begin_run(&"level_01")
	GameState.register_level_spawn(Vector2.ZERO, 0)
	var arena := Node2D.new()
	get_tree().root.add_child(arena)
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PocketPlayer
	arena.add_child(player)
	await get_tree().physics_frame
	var lives_before := GameState.lives
	_check(player.activate_shield(), "An unshielded player should accept a shield")
	_check(player.has_shield, "Activating a shield should update player state")
	_check(not player.activate_shield(), "A shield should not stack")
	player.request_death()
	_check(not player.has_shield, "The first damaging contact should consume the shield")
	_check(GameState.lives == lives_before, "A shielded hit should not remove a life")
	player.set("_spawn_protected", false)
	player.request_death()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(GameState.lives == lives_before - 1, "An unshielded hit should use the normal death flow")
	_check(not player.has_shield, "Respawning should leave the shield reset")
	arena.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _test_enemy_bonus() -> void:
	GameState.debug_begin_run(&"level_01")
	GameState.register_level_spawn(Vector2.ZERO, 0)
	var arena := Node2D.new()
	get_tree().root.add_child(arena)
	var enemy := PocketEnemy.new()
	enemy.maximum_health = 2
	enemy.defeat_time_bonus = 2.0
	arena.add_child(enemy)
	await get_tree().physics_frame
	GameState.elapsed_time = 12.0

	_check(enemy.receive_stomp(), "A healthy enemy should accept a stomp")
	_check(is_equal_approx(GameState.elapsed_time, 12.0), "A non-lethal stomp should not award the defeat bonus")
	enemy._reset_stomp_cooldown()
	_check(enemy.receive_stomp(), "A damaged enemy should accept the lethal stomp")
	_check(is_equal_approx(GameState.elapsed_time, 10.0), "Defeating an enemy should deduct two seconds from the run timer")
	_check(enemy.collision_layer == 0, "A defeated enemy should retain its existing collision shutdown behavior")

	GameState.elapsed_time = 1.0
	_check(GameState.award_enemy_time_bonus(2.0), "A valid time bonus should be accepted during play")
	_check(is_zero_approx(GameState.elapsed_time), "A time bonus should never make the run timer negative")
	GameState.run_status = GameState.RunStatus.COMPLETE
	_check(not GameState.award_enemy_time_bonus(2.0), "A time bonus should not alter a completed run")

	GameState.debug_begin_run(&"level_01")
	GameState.register_level_spawn(Vector2.ZERO, 0)
	var ui_scene := load("res://scenes/ui/gameplay_ui.tscn") as PackedScene
	var ui := ui_scene.instantiate() as GameplayUi
	arena.add_child(ui)
	await get_tree().process_frame
	GameState.elapsed_time = 8.0
	GameState.award_enemy_time_bonus(2.0)
	await get_tree().process_frame
	var popup := ui.find_child("TimeBonusPopup", true, false) as Label
	_check(popup != null and popup.text == "-2.0s", "The HUD should show immediate feedback for an enemy time bonus")
	arena.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _test_scenes() -> void:
	var required_scenes := [
		"res://scenes/ui/main_menu.tscn",
		"res://scenes/ui/level_select.tscn",
		"res://scenes/ui/gameplay_ui.tscn",
		"res://scenes/player/player.tscn",
		"res://scenes/enemies/walker.tscn",
		"res://scenes/enemies/ledge_patroller.tscn",
		"res://scenes/enemies/bruiser.tscn",
		"res://scenes/gameplay/collectible.tscn",
		"res://scenes/gameplay/powerup.tscn",
		"res://scenes/gameplay/shield_pickup.tscn",
		"res://scenes/gameplay/falling_spike.tscn",
		"res://scenes/gameplay/checkpoint.tscn",
		"res://scenes/gameplay/breakable_block.tscn",
		"res://scenes/gameplay/moving_platform.tscn",
		"res://scenes/gameplay/spike_hazard.tscn",
		"res://scenes/gameplay/warp_zone.tscn",
		"res://scenes/gameplay/level_exit.tscn",
		"res://scenes/levels/level_01.tscn",
		"res://scenes/levels/level_02.tscn",
		"res://scenes/levels/level_03.tscn",
	]
	for path: String in required_scenes:
		_check(ResourceLoader.exists(path), "Scene should exist: %s" % path)
		_check(load(path) is PackedScene, "Scene should parse as PackedScene: %s" % path)

	GameState.debug_begin_run(&"level_01")
	var level_scene := load("res://scenes/levels/level_01.tscn") as PackedScene
	var level := level_scene.instantiate()
	get_tree().root.add_child(level)
	for frame in 8:
		await get_tree().physics_frame
	_check(level.get_node_or_null("Ground") is TileMapLayer, "Level should build a Ground TileMapLayer")
	_check(level.get_node_or_null("OneWayPlatforms") is TileMapLayer, "Level should build a one-way TileMapLayer")
	_check(level.get_node_or_null("Player") is PocketPlayer, "Level should contain the player")
	_check(get_tree().get_nodes_in_group(&"enemy").size() == 6, "Level should contain six enemy instances")
	_check(GameState.collectible_total == 14, "Level should expose fourteen collectible locations")
	_check(level.get_node_or_null("KillPlane") is DeathZone, "Level should contain a kill plane")
	var player := level.get_node_or_null("Player") as PocketPlayer
	if player != null:
		var starting_x := player.global_position.x
		Input.action_press(&"move_right")
		for frame in 45:
			await get_tree().physics_frame
		Input.action_release(&"move_right")
		_check(player.global_position.x > starting_x + 70.0, "Player input should move the character to the right")
		_check(player.animation_state == PocketPlayer.AnimationState.RUN, "Ground movement should use the run animation")

		for frame in 5:
			await get_tree().physics_frame
		var grounded_y := player.global_position.y
		Input.action_press(&"jump")
		await get_tree().physics_frame
		Input.action_release(&"jump")
		for frame in 4:
			await get_tree().physics_frame
		_check(player.global_position.y < grounded_y - 8.0, "Player input should launch a jump")
	Input.action_release(&"move_right")
	Input.action_release(&"jump")
	level.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	GameState.debug_begin_run(&"level_02")
	var level_2_scene := load("res://scenes/levels/level_02.tscn") as PackedScene
	var level_2 := level_2_scene.instantiate()
	get_tree().root.add_child(level_2)
	for frame in 8:
		await get_tree().physics_frame
	_check(level_2.get_node_or_null("Ground") is TileMapLayer, "Level 2 should build a Ground TileMapLayer")
	_check(level_2.get_node_or_null("OneWayPlatforms") is TileMapLayer, "Level 2 should build a one-way TileMapLayer")
	_check(level_2.get_node_or_null("Player") is PocketPlayer, "Level 2 should contain the player")
	_check(get_tree().get_nodes_in_group(&"enemy").size() == 8, "Level 2 should contain eight enemy instances")
	_check(level_2.find_children("*", "PocketPowerup", true, false).size() >= 1, "Level 2 should introduce a PocketPowerup")
	_check(level_2.find_children("*", "PocketMovingPlatform", true, false).size() >= 1, "Level 2 should contain a moving platform")
	_check(level_2.find_children("*", "PocketCheckpoint", true, false).size() == 1, "Level 2 should contain one checkpoint")
	_check(level_2.find_children("*", "PocketWarpZone", true, false).size() == 2, "Level 2 should contain a two-way secret-area warp")
	_check(level_2.find_children("*", "PocketLevelExit", true, false).size() == 1, "Level 2 should contain a level exit")
	_check(GameState.collectible_total == 15, "Level 2 should expose fifteen collectible locations")
	_check(level_2.get_node_or_null("KillPlane") is DeathZone, "Level 2 should contain a kill plane")
	level_2.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	GameState.debug_begin_run(&"level_03")
	var level_3 := (load("res://scenes/levels/level_03.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(level_3)
	for frame in 8:
		await get_tree().physics_frame
	_check(level_3.find_children("*", "ShieldPickup", true, false).size() == 3, "Level 3 should contain exactly three shield pickups")
	_check(level_3.find_children("*", "PocketMovingPlatform", true, false).size() == 1, "Level 3 should contain its moving bridge")
	_check(level_3.find_children("*", "FallingSpike", true, false).size() == 1, "Level 3 should contain its falling spike tutorial")
	_check(get_tree().get_nodes_in_group(&"enemy").size() == 4, "Level 3 should contain four enemies")
	_check(level_3.find_children("*", "PocketLevelExit", true, false).size() == 1, "Level 3 should contain a level exit")
	_check(GameState.collectible_total == 12, "Level 3 should expose twelve collectible locations")
	level_3.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _on_respawn_requested(position: Vector2) -> void:
	_respawn_position = position


func _wait_for_floor(player: PocketPlayer, max_frames := 180) -> bool:
	for frame in max_frames:
		if player.is_on_floor():
			return true
		await get_tree().physics_frame
	return player.is_on_floor()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
