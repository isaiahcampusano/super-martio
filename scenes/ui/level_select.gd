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
	var subtitle := PocketUiStyle.make_label("Clear each expedition to unlock the trail ahead.", 18, PocketUiStyle.MUTED)
	column.add_child(subtitle)

	var cards := HBoxContainer.new()
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 18)
	column.add_child(cards)

	var first_available_button: Button
	var descriptions := {
		&"level_01": "A bright forest trail with crumbling blocks, strange walkers, and a secret sky-room.",
		&"level_02": "A charcoal cavern of amber crystals, tight patrols, moving lifts, and a hidden vault.",
	}
	var level_ids := LevelCatalog.get_level_ids()
	for index in level_ids.size():
		var level_id := level_ids[index]
		var start_button := _add_level_card(cards, level_id, index + 1, descriptions.get(level_id, ""))
		if first_available_button == null and not start_button.disabled:
			first_available_button = start_button

	var back_button := Button.new()
	back_button.text = "Back"
	PocketUiStyle.style_button(back_button, PocketUiStyle.LAVENDER)
	back_button.pressed.connect(_on_back_pressed)
	column.add_child(back_button)
	if first_available_button != null:
		first_available_button.grab_focus()


func _add_level_card(parent: HBoxContainer, level_id: StringName, number: int, description_text: String) -> Button:
	var unlocked := LevelCatalog.is_unlocked(level_id, GameState.completed_levels)
	var title := LevelCatalog.get_title(level_id)
	var accent := PocketUiStyle.MINT if number == 1 else PocketUiStyle.GOLD
	var border := Color("416a73") if number == 1 else Color("8a6534")

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", PocketUiStyle.panel(Color("172744"), 22, border))
	parent.add_child(card)

	var card_column := VBoxContainer.new()
	card_column.alignment = BoxContainer.ALIGNMENT_CENTER
	card_column.add_theme_constant_override("separation", 14)
	card.add_child(card_column)

	var level_title := PocketUiStyle.make_label("%02d  •  %s" % [number, title.to_upper()], 26, accent)
	level_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_column.add_child(level_title)
	var description := PocketUiStyle.make_label(description_text, 16, PocketUiStyle.TEXT)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_column.add_child(description)

	var status_text := "Not yet completed"
	if not unlocked:
		status_text = "Locked  •  Clear %s" % LevelCatalog.get_title(LevelCatalog.get_required_level(level_id))
	elif GameState.completed_levels.has(String(level_id)):
		var level_key := String(level_id)
		var best_time := float(GameState.best_times.get(level_key, 0.0))
		var best_seeds := int(GameState.best_collectibles.get(level_key, 0))
		status_text = "Completed  •  Best %s  •  Seeds %d" % [_format_time(best_time), best_seeds]
	var status := PocketUiStyle.make_label(status_text, 15, PocketUiStyle.GOLD)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_column.add_child(status)

	var start_button := Button.new()
	start_button.text = "Start %s" % title if unlocked else "Locked"
	start_button.disabled = not unlocked
	PocketUiStyle.style_button(start_button, accent)
	start_button.pressed.connect(_on_start_pressed.bind(level_id))
	card_column.add_child(start_button)
	return start_button


func _format_time(seconds: float) -> String:
	var minutes := int(seconds) / 60
	var whole_seconds := int(seconds) % 60
	var centiseconds := int(seconds * 100.0) % 100
	return "%02d:%02d.%02d" % [minutes, whole_seconds, centiseconds]


func _on_start_pressed(level_id: StringName) -> void:
	GameState.start_level(level_id)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
