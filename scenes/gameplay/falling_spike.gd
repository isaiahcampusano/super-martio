class_name FallingSpike
extends Area2D


@export var trigger_size := Vector2(220.0, 300.0)
@export var fall_speed := 620.0
@export var max_fall_distance := 360.0

var _falling := false
var _start_y := 0.0


func _ready() -> void:
	collision_layer = 1 << 3
	collision_mask = 1 << 1
	monitoring = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(34.0, 52.0)
	collision.shape = shape
	add_child(collision)
	var trigger := Area2D.new()
	trigger.collision_layer = 0
	trigger.collision_mask = 1 << 1
	var trigger_collision := CollisionShape2D.new()
	var trigger_shape := RectangleShape2D.new()
	trigger_shape.size = trigger_size
	trigger_collision.shape = trigger_shape
	trigger_collision.position.y = trigger_size.y * 0.5 + 24.0
	trigger.add_child(trigger_collision)
	trigger.body_entered.connect(_on_trigger_entered)
	add_child(trigger)
	body_entered.connect(_on_body_entered)
	_start_y = position.y
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not _falling:
		return
	position.y += fall_speed * delta
	if position.y >= _start_y + max_fall_distance:
		queue_free()


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-17.0, -26.0), Vector2(17.0, -26.0), Vector2(0.0, 26.0),
	]), Color("5ad7ff"))
	draw_line(Vector2(-12.0, -22.0), Vector2(0.0, 18.0), Color("dffaff"), 3.0)


func _on_trigger_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_falling = true


func _on_body_entered(body: Node2D) -> void:
	if body.has_method(&"request_death"):
		body.call(&"request_death")
