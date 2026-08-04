class_name DeathZone
extends Area2D


@export var zone_size := Vector2(5000.0, 160.0)


func _ready() -> void:
	collision_layer = 1 << 3
	collision_mask = 1 << 1
	monitoring = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = zone_size
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method(&"request_death"):
		body.call(&"request_death")

