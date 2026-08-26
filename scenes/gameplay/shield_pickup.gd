class_name ShieldPickup
extends Area2D


@export var float_speed := 2.2
@export var float_height := 5.0

var collected := false
var _resting_y := 0.0
var _time := 0.0


func _ready() -> void:
	collision_layer = 1 << 4
	collision_mask = 1 << 1
	monitoring = true
	monitorable = true
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 17.0
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	_resting_y = position.y
	queue_redraw()


func _process(delta: float) -> void:
	if collected:
		return
	_time += delta
	position.y = _resting_y + sin(_time * float_speed) * float_height
	rotation = sin(_time * 1.6) * 0.08
	queue_redraw()


func _draw() -> void:
	var pulse := (sin(_time * 4.0) + 1.0) * 0.5
	draw_circle(Vector2.ZERO, 22.0 + pulse * 2.0, Color(0.18, 0.68, 1.0, 0.13))
	var shield := PackedVector2Array([
		Vector2(0.0, -17.0), Vector2(15.0, -11.0), Vector2(12.0, 7.0),
		Vector2(0.0, 18.0), Vector2(-12.0, 7.0), Vector2(-15.0, -11.0),
	])
	draw_colored_polygon(shield, Color("38bdf8"))
	draw_polyline(shield, Color("d9f7ff"), 2.5)
	draw_line(Vector2(0.0, -11.0), Vector2(0.0, 11.0), Color(0.88, 0.98, 1.0, 0.75), 2.0)


func _on_body_entered(body: Node2D) -> void:
	if collected or not body.has_method(&"activate_shield"):
		return
	if not bool(body.call(&"activate_shield")):
		return
	collected = true
	monitoring = false
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.18)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)
