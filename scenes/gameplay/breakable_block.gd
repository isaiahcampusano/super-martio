class_name BreakableBlock
extends StaticBody2D


const POWERUP_SCENE := preload("res://scenes/gameplay/powerup.tscn")

@export var block_size := Vector2(48.0, 48.0)
var used := false
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
	if used:
		return
	used = true
	_spawn_powerup()
	queue_redraw()
	PocketSfx.play(self, 520.0, 0.12, -12.0, 180.0)
	var resting_y := position.y
	var tween := create_tween()
	tween.tween_property(self, "position:y", resting_y - 7.0, 0.07)
	tween.tween_property(self, "position:y", resting_y, 0.09)


func _spawn_powerup() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var powerup := POWERUP_SCENE.instantiate() as PocketPowerup
	if parent is Node2D:
		powerup.position = (parent as Node2D).to_local(global_position)
	else:
		powerup.position = global_position
	parent.add_child(powerup)


func _draw() -> void:
	var fill := Color("776f78") if used else Color("d6933d")
	var edge := Color("4b4653") if used else Color("ffe17a")
	var detail := Color("aaa0a3") if used else Color("8f573d")
	draw_rect(Rect2(-block_size * 0.5, block_size), fill, true)
	draw_rect(Rect2(-block_size * 0.5 + Vector2(4.0, 4.0), block_size - Vector2(8.0, 8.0)), edge, false, 4.0)
	if used:
		draw_line(Vector2(-10.0, 0.0), Vector2(10.0, 0.0), detail, 4.0)
	else:
		draw_circle(Vector2(0.0, -6.0), 9.0, detail, false, 4.0)
		draw_line(Vector2(7.0, -11.0), Vector2(0.0, 2.0), detail, 4.0)
		draw_circle(Vector2(0.0, 11.0), 2.5, detail)
