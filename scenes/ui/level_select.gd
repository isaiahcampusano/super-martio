extends Control


func _ready() -> void:
	InputSetup.ensure_default_actions()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_screen()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0d1931"), true)
	for index in 10:
		var x := 70.0 + float(index) * 105.0
		var height := 90.0 + float((index * 37) % 170)
		draw_rect(Rect2(x, size.y - height, 70.0, height), Color(0.18, 0.33, 0.42, 0.20), true)


func _build_screen() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_right", 72)
	margin.add_theme_constant_override("margin_top", 54)
	margin.add_theme_constant_override("margin_bottom", 54)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	var title := PocketUiStyle.make_label("Choose a Trail", 44)
	column.add_child(title)
	var subtitle := PocketUiStyle.make_label("One complete expedition is ready for V1.", 18, PocketUiStyle.MUTED)
	column.add_child(subtitle)

	var card := PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", PocketUiStyle.panel(Color("172744"), 22, Color("416a73")))
	column.add_child(card)

	var card_column := VBoxContainer.new()
	card_column.alignment = BoxContainer.ALIGNMENT_CENTER
	card_column.add_theme_constant_override("separation", 14)
	card.add_child(card_column)

	var level_title := PocketUiStyle.make_label("01  •  MOSSLIGHT RUN", 31, PocketUiStyle.MINT)
	level_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_column.add_child(level_title)
	var description := PocketUiStyle.make_label("A bright forest trail with crumbling blocks, strange walkers,\na secret sky-room, and a sleeping gate at the far edge.", 18, PocketUiStyle.TEXT)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_column.add_child(description)

	var status_text := "Not yet completed"
	if GameState.completed_levels.has("level_01"):
		var best_time := float(GameState.best_times.get("level_01", 0.0))
		var best_seeds := int(GameState.best_collectibles.get("level_01", 0))
		status_text = "Completed  •  Best %s  •  Best seeds %d" % [_format_time(best_time), best_seeds]
	var status := PocketUiStyle.make_label(status_text, 16, PocketUiStyle.GOLD)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_column.add_child(status)

	var start_button := Button.new()
	start_button.text = "Start Mosslight Run"
	PocketUiStyle.style_button(start_button, PocketUiStyle.MINT)
	start_button.pressed.connect(_on_start_pressed)
	card_column.add_child(start_button)

	var back_button := Button.new()
	back_button.text = "Back"
	PocketUiStyle.style_button(back_button, PocketUiStyle.LAVENDER)
	back_button.pressed.connect(_on_back_pressed)
	column.add_child(back_button)
	start_button.grab_focus()


func _format_time(seconds: float) -> String:
	var minutes := int(seconds) / 60
	var whole_seconds := int(seconds) % 60
	var centiseconds := int(seconds * 100.0) % 100
	return "%02d:%02d.%02d" % [minutes, whole_seconds, centiseconds]


func _on_start_pressed() -> void:
	GameState.start_level(&"level_01")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

