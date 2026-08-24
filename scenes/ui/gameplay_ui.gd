class_name GameplayUi
extends CanvasLayer


var _lives_label: Label
var _seeds_label: Label
var _time_label: Label
var _overlay: ColorRect
var _modal_title: Label
var _modal_details: Label
var _button_column: VBoxContainer
var _overlay_mode := ""


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()
	_build_overlay()
	GameState.lives_changed.connect(_on_lives_changed)
	GameState.collectibles_changed.connect(_on_collectibles_changed)
	GameState.time_bonus_awarded.connect(_on_time_bonus_awarded)
	GameState.game_over.connect(_on_game_over)
	GameState.level_completed.connect(_on_level_completed)
	_on_lives_changed(GameState.lives)
	_on_collectibles_changed(GameState.collected_count(), GameState.collectible_total)


func _process(_delta: float) -> void:
	_time_label.text = "TIME  %s" % _format_time(GameState.elapsed_time)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"):
		return
	if _overlay_mode == "pause":
		_resume()
	elif _overlay_mode.is_empty() and GameState.run_status == GameState.RunStatus.PLAYING:
		_show_pause()
	get_viewport().set_input_as_handled()


func _build_hud() -> void:
	var hud := PanelContainer.new()
	hud.position = Vector2(22.0, 20.0)
	hud.size = Vector2(610.0, 62.0)
	hud.add_theme_stylebox_override("panel", PocketUiStyle.panel(Color(0.055, 0.10, 0.19, 0.92), 14, Color("355371")))
	add_child(hud)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 32)
	hud.add_child(row)
	_lives_label = PocketUiStyle.make_label("LIVES  3", 19, PocketUiStyle.MINT)
	_seeds_label = PocketUiStyle.make_label("SEEDS  0/0", 19, PocketUiStyle.GOLD)
	_time_label = PocketUiStyle.make_label("TIME  00:00.00", 19, PocketUiStyle.TEXT)
	row.add_child(_lives_label)
	row.add_child(_seeds_label)
	row.add_child(_time_label)

	var hint := PocketUiStyle.make_label("Space: jump / double-jump   Shift: sprint   S/↓: crouch or doorway   Esc: pause", 14, PocketUiStyle.MUTED)
	hint.position = Vector2(24.0, 500.0)
	add_child(hint)


func _build_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0.02, 0.035, 0.075, 0.84)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520.0, 330.0)
	panel.add_theme_stylebox_override("panel", PocketUiStyle.panel(Color("172744"), 24, Color("53669b")))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	_modal_title = PocketUiStyle.make_label("Paused", 38, PocketUiStyle.TEXT)
	_modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_modal_title)
	_modal_details = PocketUiStyle.make_label("", 17, PocketUiStyle.MUTED)
	_modal_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_modal_details)
	_button_column = VBoxContainer.new()
	_button_column.alignment = BoxContainer.ALIGNMENT_CENTER
	_button_column.add_theme_constant_override("separation", 10)
	column.add_child(_button_column)


func _show_pause() -> void:
	_overlay_mode = "pause"
	_modal_title.text = "Trail Paused"
	_modal_details.text = "Take a breath. The timer and the whole level are frozen."
	_replace_buttons([
		["Resume", Callable(self, "_resume"), PocketUiStyle.MINT],
		["Restart Level", Callable(self, "_restart"), PocketUiStyle.GOLD],
		["Level Select", Callable(self, "_level_select"), PocketUiStyle.LAVENDER],
	])
	_overlay.visible = true
	get_tree().paused = true


func _on_game_over() -> void:
	_overlay_mode = "game_over"
	_modal_title.text = "The Trail Went Quiet"
	_modal_details.text = "No lives remain. Try the whole run again from the beginning."
	_replace_buttons([
		["Try Again", Callable(self, "_restart"), PocketUiStyle.MINT],
		["Level Select", Callable(self, "_level_select"), PocketUiStyle.LAVENDER],
	])
	_overlay.visible = true
	get_tree().paused = true


func _on_level_completed(summary: Dictionary) -> void:
	_overlay_mode = "complete"
	_modal_title.text = "Mosslight Gate Awakened!"
	_modal_details.text = "Time  %s\nStar Seeds  %d / %d" % [
		_format_time(float(summary["time"])),
		int(summary["collected"]),
		int(summary["total"]),
	]
	_replace_buttons([
		["Replay", Callable(self, "_restart"), PocketUiStyle.MINT],
		["Level Select", Callable(self, "_level_select"), PocketUiStyle.LAVENDER],
	])
	_overlay.visible = true
	get_tree().paused = true


func _replace_buttons(specs: Array) -> void:
	for child in _button_column.get_children():
		_button_column.remove_child(child)
		child.queue_free()
	var first: Button
	for spec: Array in specs:
		var button := Button.new()
		button.text = spec[0] as String
		PocketUiStyle.style_button(button, spec[2] as Color)
		button.pressed.connect(spec[1] as Callable)
		_button_column.add_child(button)
		if first == null:
			first = button
	if first != null:
		first.grab_focus.call_deferred()


func _resume() -> void:
	get_tree().paused = false
	_overlay.visible = false
	_overlay_mode = ""


func _restart() -> void:
	get_tree().paused = false
	_overlay.visible = false
	_overlay_mode = ""
	GameState.restart_level()


func _level_select() -> void:
	get_tree().paused = false
	GameState.return_to_level_select()


func _on_lives_changed(value: int) -> void:
	_lives_label.text = "LIVES  %d" % value


func _on_collectibles_changed(value: int, total: int) -> void:
	_seeds_label.text = "SEEDS  %d/%d" % [value, total]


func _on_time_bonus_awarded(seconds: float) -> void:
	var popup := PocketUiStyle.make_label("-%.1fs" % seconds, 22, PocketUiStyle.MINT)
	popup.name = "TimeBonusPopup"
	popup.position = Vector2(492.0, 74.0)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(popup)
	var tween := popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 28.0, 0.85)
	tween.tween_property(popup, "modulate:a", 0.0, 0.85).set_delay(0.25)
	tween.chain().tween_callback(popup.queue_free)


func _format_time(seconds: float) -> String:
	var minutes := int(seconds) / 60
	var whole_seconds := int(seconds) % 60
	var centiseconds := int(seconds * 100.0) % 100
	return "%02d:%02d.%02d" % [minutes, whole_seconds, centiseconds]
