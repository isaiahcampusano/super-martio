class_name PocketWarpZone
extends Area2D


@export var target_position := Vector2.ZERO
@export var target_camera_bounds := Rect2i(0, 0, 960, 540)
@export var accent_color := Color("7f8dff")

var _player: PocketPlayer
var _label: Label


func _ready() -> void:
	collision_layer = 1 << 4
	collision_mask = 1 << 1
	monitoring = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(64.0, 72.0)
	collision.shape = shape
	collision.position.y = -12.0
	add_child(collision)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_label = Label.new()
	_label.text = "↓"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-24.0, -86.0)
	_label.size = Vector2(48.0, 32.0)
	_label.add_theme_font_size_override("font_size", 25)
	_label.visible = false
	add_child(_label)
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if is_instance_valid(_player) and Input.is_action_just_pressed(&"crouch"):
		var player_to_move := _player
		_player = null
		_label.visible = false
		PocketSfx.play(self, 320.0, 0.16, -15.0, -180.0)
		player_to_move.teleport_to(target_position, target_camera_bounds)


func _draw() -> void:
	draw_rect(Rect2(-32.0, -48.0, 64.0, 48.0), accent_color, true)
	draw_rect(Rect2(-40.0, -58.0, 80.0, 14.0), accent_color.lightened(0.2), true)
	draw_rect(Rect2(-21.0, -40.0, 42.0, 40.0), Color("17233f"), true)


func _on_body_entered(body: Node2D) -> void:
	if body is PocketPlayer:
		_player = body as PocketPlayer
		_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		_label.visible = false

