class_name WorldBlock
extends StaticBody2D


var block_size := Vector2(96.0, 48.0)
var block_color := Color("273b63")


func _ready() -> void:
	collision_layer = 1 << 0
	collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = block_size
	collision.shape = shape
	add_child(collision)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-block_size * 0.5, block_size), block_color, true)
	draw_rect(Rect2(-block_size * 0.5, Vector2(block_size.x, 7.0)), block_color.lightened(0.2), true)

