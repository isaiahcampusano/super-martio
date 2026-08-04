class_name PocketLevelExit
extends Area2D


var _used := false


func _ready() -> void:
	collision_layer = 1 << 4
	collision_mask = 1 << 1
	monitoring = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(64.0, 120.0)
	collision.shape = shape
	collision.position = Vector2(0.0, -36.0)
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _process(delta: float) -> void:
	rotation = sin(Time.get_ticks_msec() * 0.0018) * 0.02
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2(0.0, -44.0), 34.0, PI, TAU, 24, Color("7f8dff"), 9.0)
	draw_line(Vector2(-34.0, -44.0), Vector2(-34.0, 22.0), Color("7f8dff"), 9.0)
	draw_line(Vector2(34.0, -44.0), Vector2(34.0, 22.0), Color("7f8dff"), 9.0)
	draw_circle(Vector2.ZERO, 20.0, Color(0.42, 0.92, 0.82, 0.30))
	draw_circle(Vector2.ZERO, 8.0, Color("f8e45c"))


func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group(&"player"):
		return
	_used = true
	PocketSfx.play(self, 420.0, 0.45, -9.0, 520.0)
	GameState.complete_level()

