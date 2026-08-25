extends Node


signal lives_changed(value: int)
signal collectibles_changed(value: int, total: int)
signal time_bonus_awarded(seconds: float)
signal checkpoint_changed(checkpoint_id: StringName)
signal respawn_requested(position: Vector2)
signal game_over
signal level_completed(summary: Dictionary)

enum RunStatus { IDLE, LOADING, PLAYING, RESPAWNING, GAME_OVER, COMPLETE }

const STARTING_LIVES := 3
const LEVEL_SELECT_SCENE := "res://scenes/ui/level_select.tscn"

var run_status: RunStatus = RunStatus.IDLE
var current_level_id: StringName = &""
var lives := STARTING_LIVES
var elapsed_time := 0.0
var collectible_total := 0
var checkpoint_id: StringName = &""
var spawn_position := Vector2.ZERO
var spawn_registered := false

var completed_levels := PackedStringArray()
var best_times: Dictionary = {}
var best_collectibles: Dictionary = {}

var _collected_ids: Dictionary = {}
var _save_store := SaveStore.new()


func _ready() -> void:
	var progress := _save_store.load_progress()
	completed_levels = progress["completed_levels"] as PackedStringArray
	best_times = progress["best_times"] as Dictionary
	best_collectibles = progress["best_collectibles"] as Dictionary


func _process(delta: float) -> void:
	if run_status == RunStatus.PLAYING:
		elapsed_time += delta


func start_level(level_id: StringName) -> Error:
	var path := LevelCatalog.get_scene_path(level_id)
	if path.is_empty():
		push_error("Unknown level id: %s" % level_id)
		return ERR_DOES_NOT_EXIST
	if not LevelCatalog.is_unlocked(level_id, completed_levels):
		push_warning("Level is still locked: %s" % level_id)
		return ERR_UNAUTHORIZED
	_reset_run(level_id)
	run_status = RunStatus.LOADING
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		run_status = RunStatus.IDLE
		push_error("Could not load level %s: %s" % [level_id, error_string(error)])
	return error


func ensure_level_context(level_id: StringName) -> void:
	if current_level_id != level_id or run_status == RunStatus.IDLE:
		_reset_run(level_id)
		run_status = RunStatus.LOADING


func register_level_spawn(position: Vector2, total: int) -> void:
	if not spawn_registered:
		spawn_position = position
		spawn_registered = true
	collectible_total = maxi(0, total)
	run_status = RunStatus.PLAYING
	lives_changed.emit(lives)
	collectibles_changed.emit(_collected_ids.size(), collectible_total)


func activate_checkpoint(new_checkpoint_id: StringName, new_spawn_position: Vector2) -> void:
	if run_status != RunStatus.PLAYING or checkpoint_id == new_checkpoint_id:
		return
	checkpoint_id = new_checkpoint_id
	spawn_position = new_spawn_position
	checkpoint_changed.emit(checkpoint_id)


func register_collectible(collectible_id: StringName) -> bool:
	if run_status != RunStatus.PLAYING or _collected_ids.has(collectible_id):
		return false
	_collected_ids[collectible_id] = true
	collectibles_changed.emit(_collected_ids.size(), collectible_total)
	return true


func grant_extra_life() -> bool:
	if run_status != RunStatus.PLAYING:
		return false
	lives += 1
	lives_changed.emit(lives)
	return true


func award_enemy_time_bonus(seconds: float) -> bool:
	if run_status != RunStatus.PLAYING or seconds <= 0.0:
		return false
	elapsed_time = maxf(0.0, elapsed_time - seconds)
	time_bonus_awarded.emit(seconds)
	return true


func request_player_death() -> void:
	if run_status != RunStatus.PLAYING:
		return
	lives = maxi(0, lives - 1)
	lives_changed.emit(lives)
	if lives > 0:
		run_status = RunStatus.RESPAWNING
		respawn_requested.emit.call_deferred(spawn_position)
	else:
		run_status = RunStatus.GAME_OVER
		game_over.emit.call_deferred()


func confirm_respawn() -> void:
	if run_status == RunStatus.RESPAWNING:
		run_status = RunStatus.PLAYING


func restart_level() -> Error:
	if current_level_id.is_empty():
		return ERR_DOES_NOT_EXIST
	return start_level(current_level_id)


func complete_level() -> void:
	if run_status != RunStatus.PLAYING:
		return
	run_status = RunStatus.COMPLETE
	var level_key := String(current_level_id)
	if not completed_levels.has(level_key):
		completed_levels.append(level_key)
	var collected_count := _collected_ids.size()
	if not best_times.has(level_key) or elapsed_time < float(best_times[level_key]):
		best_times[level_key] = elapsed_time
	if collected_count > int(best_collectibles.get(level_key, 0)):
		best_collectibles[level_key] = collected_count
	_save_store.save_progress(completed_levels, best_times, best_collectibles)
	level_completed.emit.call_deferred({
		"level_id": current_level_id,
		"time": elapsed_time,
		"collected": collected_count,
		"total": collectible_total,
	})


func return_to_level_select() -> Error:
	get_tree().paused = false
	run_status = RunStatus.IDLE
	return get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)


func collected_count() -> int:
	return _collected_ids.size()


func debug_begin_run(level_id: StringName = &"level_01") -> void:
	_reset_run(level_id)
	run_status = RunStatus.LOADING


func set_test_save_path(path: String) -> void:
	_save_store.save_path = path


func _reset_run(level_id: StringName) -> void:
	get_tree().paused = false
	current_level_id = level_id
	lives = STARTING_LIVES
	elapsed_time = 0.0
	collectible_total = 0
	checkpoint_id = &""
	spawn_position = Vector2.ZERO
	spawn_registered = false
	_collected_ids.clear()
	lives_changed.emit(lives)
	collectibles_changed.emit(0, 0)
