class_name PocketCheckpoint
extends Area2D


@export var checkpoint_id: StringName = &"checkpoint"
@export var spawn_offset := Vector2(0.0, -34.0)
var _active := false


func _ready() -> void:
	collision_layer = 1 << 4
	collision_mask = 1 << 1
	monitoring = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(52.0, 96.0)
	collision.shape = shape
	collision.position = Vector2(0.0, -24.0)
	add_child(collision)
	body_entered.connect(_on_body_entered)
	GameState.checkpoint_changed.connect(_on_checkpoint_changed)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-4.0, -78.0, 8.0, 86.0), Color("d5e2ff"), true)
	draw_circle(Vector2.ZERO, 12.0, Color("273b63"))
	var flag_color := Color("65e6b4") if _active else Color("6c7b9c")
	draw_colored_polygon(PackedVector2Array([Vector2(4.0, -72.0), Vector2(48.0, -58.0), Vector2(4.0, -42.0)]), flag_color)
	if _active:
		draw_circle(Vector2(19.0, -57.0), 5.0, Color("f8e45c"))


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	GameState.activate_checkpoint(checkpoint_id, global_position + spawn_offset)


func _on_checkpoint_changed(value: StringName) -> void:
	if value != checkpoint_id or _active:
		return
	_active = true
	PocketSfx.play(self, 540.0, 0.20, -14.0, 320.0)
	queue_redraw()

