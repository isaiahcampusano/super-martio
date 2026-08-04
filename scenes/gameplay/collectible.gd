class_name StarSeed
extends Area2D


@export var collectible_id: StringName = &"seed"
var _base_y := 0.0
var _time := 0.0
var _taken := false


func _ready() -> void:
	collision_layer = 1 << 4
	collision_mask = 1 << 1
	monitoring = true
	monitorable = true
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	_base_y = position.y
	queue_redraw()


func _process(delta: float) -> void:
	if _taken:
		return
	_time += delta
	position.y = _base_y + sin(_time * 3.4) * 5.0
	rotation = sin(_time * 2.1) * 0.14
	queue_redraw()


func _draw() -> void:
	var points := PackedVector2Array([
		Vector2(0.0, -15.0), Vector2(6.0, -6.0), Vector2(15.0, 0.0),
		Vector2(6.0, 6.0), Vector2(0.0, 15.0), Vector2(-6.0, 6.0),
		Vector2(-15.0, 0.0), Vector2(-6.0, -6.0),
	])
	draw_colored_polygon(points, Color("f8e45c"))
	draw_polyline(points, Color("fff8bd"), 2.0)
	draw_circle(Vector2(-3.0, -4.0), 3.0, Color("fffbd6"))


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body.is_in_group(&"player"):
		return
	if not GameState.register_collectible(collectible_id):
		return
	_taken = true
	monitoring = false
	PocketSfx.play(self, 760.0, 0.10, -14.0, 420.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.7, 1.7), 0.16)
	tween.tween_property(self, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(queue_free)

