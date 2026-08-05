extends Control


var _time := 0.0


func _ready() -> void:
	InputSetup.ensure_default_actions()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_menu()
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0a1430"), true)
	draw_circle(Vector2(size.x * 0.78, size.y * 0.26), 150.0, Color(0.27, 0.33, 0.70, 0.23))
	draw_circle(Vector2(size.x * 0.18, size.y * 0.78), 190.0, Color(0.16, 0.68, 0.54, 0.16))
	for index in 28:
		var x := fposmod(float(index * 157) + _time * (7.0 + index % 4), maxf(1.0, size.x))
		var y := fposmod(float(index * 83), maxf(1.0, size.y))
		var radius := 1.5 + float(index % 3)
		draw_circle(Vector2(x, y), radius, Color(0.85, 0.96, 1.0, 0.52))


func _build_menu() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(530.0, 410.0)
	panel.add_theme_stylebox_override("panel", PocketUiStyle.panel(Color(0.075, 0.125, 0.235, 0.94), 24))
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)

	var eyebrow := PocketUiStyle.make_label("AN ORIGINAL POCKET-SIZED ADVENTURE", 15, PocketUiStyle.MINT)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(eyebrow)

	var title := PocketUiStyle.make_label("POCKET\nPLATFORMER", 54, PocketUiStyle.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("line_spacing", -8)
	column.add_child(title)

	var subtitle := PocketUiStyle.make_label("Run fast. Find every Star Seed. Wake the Mosslight Gate.", 17, PocketUiStyle.MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 8.0
	column.add_child(spacer)

	var play_button := Button.new()
	play_button.text = "Choose a Trail"
	PocketUiStyle.style_button(play_button, PocketUiStyle.MINT)
	play_button.pressed.connect(_on_play_pressed)
	column.add_child(play_button)

	if not OS.has_feature("web"):
		var quit_button := Button.new()
		quit_button.text = "Quit"
		PocketUiStyle.style_button(quit_button, PocketUiStyle.LAVENDER)
		quit_button.pressed.connect(get_tree().quit)
		column.add_child(quit_button)

	var controls := PocketUiStyle.make_label("Move: A/D or arrows  •  Jump: Space (press again in air)\nSprint: Shift  •  Pause: Esc", 14, PocketUiStyle.MUTED)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(controls)
	play_button.grab_focus()


func _on_play_pressed() -> void:
	var error := get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
	if error != OK:
		push_error("Could not open level select: %s" % error_string(error))
