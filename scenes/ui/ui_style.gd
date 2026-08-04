class_name PocketUiStyle
extends RefCounted


const INK := Color("10213b")
const PANEL := Color("172744")
const PANEL_LIGHT := Color("20375a")
const MINT := Color("66e6b4")
const GOLD := Color("f8e45c")
const LAVENDER := Color("8996ff")
const TEXT := Color("eef7ff")
const MUTED := Color("9fb0c9")


static func panel(color: Color = PANEL, radius: int = 18, border: Color = Color("39547c")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 24.0
	return style


static func button(normal_color: Color = PANEL_LIGHT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = normal_color
	style.set_corner_radius_all(11)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 11.0
	style.content_margin_bottom = 11.0
	return style


static func style_button(control: Button, accent: Color = MINT) -> void:
	control.custom_minimum_size = Vector2(240.0, 52.0)
	control.add_theme_font_size_override("font_size", 20)
	control.add_theme_color_override("font_color", TEXT)
	control.add_theme_color_override("font_hover_color", INK)
	control.add_theme_color_override("font_focus_color", INK)
	control.add_theme_stylebox_override("normal", button())
	control.add_theme_stylebox_override("hover", button(accent))
	control.add_theme_stylebox_override("pressed", button(accent.darkened(0.12)))
	control.add_theme_stylebox_override("focus", button(accent))


static func make_label(text_value: String, font_size: int, color: Color = TEXT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

