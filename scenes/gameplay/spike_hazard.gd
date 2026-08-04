class_name SpikeHazard
extends Area2D


@export var hazard_size := Vector2(96.0, 30.0)


func _ready() -> void:
	collision_layer = 1 << 3
	collision_mask = 1 << 1
	monitoring = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(hazard_size.x, hazard_size.y * 0.58)
	collision.shape = shape
	collision.position.y = hazard_size.y * 0.18
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _draw() -> void:
	var count := maxi(1, int(hazard_size.x / 24.0))
	var step := hazard_size.x / float(count)
	for index in count:
		var left := -hazard_size.x * 0.5 + index * step
		var points := PackedVector2Array([
			Vector2(left, hazard_size.y * 0.5),
			Vector2(left + step * 0.5, -hazard_size.y * 0.5),
			Vector2(left + step, hazard_size.y * 0.5),
		])
		draw_colored_polygon(points, Color("ff5c72"))


func _on_body_entered(body: Node2D) -> void:
	if body.has_method(&"request_death"):
		body.call(&"request_death")

