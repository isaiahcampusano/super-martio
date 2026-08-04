class_name BreakableBlock
extends StaticBody2D


@export var block_size := Vector2(48.0, 48.0)
var _broken := false
var _collision: CollisionShape2D


func _ready() -> void:
	collision_layer = 1 << 0
	collision_mask = 0
	_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = block_size
	_collision.shape = shape
	add_child(_collision)
	queue_redraw()


func hit_from_below() -> void:
	if _broken:
		return
	_broken = true
	_collision.set_deferred("disabled", true)
	PocketSfx.play(self, 115.0, 0.14, -12.0, -40.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 18.0, 0.10)
	tween.tween_property(self, "scale", Vector2(1.35, 0.15), 0.18)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	draw_rect(Rect2(-block_size * 0.5, block_size), Color("c8844a"), true)
	draw_rect(Rect2(-block_size * 0.5 + Vector2(4.0, 4.0), block_size - Vector2(8.0, 8.0)), Color("e9aa5e"), false, 4.0)
	draw_line(Vector2(-18.0, 0.0), Vector2(18.0, 0.0), Color("8f573d"), 3.0)
	draw_line(Vector2(0.0, -18.0), Vector2(0.0, 18.0), Color("8f573d"), 3.0)

