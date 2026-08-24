class_name PocketPowerup
extends Area2D


@export var emerge_distance := 42.0
@export var emerge_time := 0.32

var collected := false
var _active := false
var _resting_y := 0.0
var _time := 0.0


func _ready() -> void:
	collision_layer = 1 << 4
	collision_mask = 1 << 1
	monitoring = false
	monitorable = true
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 13.0
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	_resting_y = position.y - emerge_distance
	queue_redraw()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", _resting_y, emerge_time)
	tween.tween_callback(_activate)


func _process(delta: float) -> void:
	if not _active or collected:
		return
	_time += delta
	position.y = _resting_y + sin(_time * 3.2) * 3.0
	rotation = sin(_time * 2.4) * 0.1
	queue_redraw()


func _draw() -> void:
	var points := PackedVector2Array([
		Vector2(0.0, -14.0), Vector2(5.0, -5.0), Vector2(14.0, 0.0),
		Vector2(5.0, 5.0), Vector2(0.0, 14.0), Vector2(-5.0, 5.0),
		Vector2(-14.0, 0.0), Vector2(-5.0, -5.0),
	])
	draw_colored_polygon(points, Color("ff8b5c"))
	draw_polyline(points, Color("fff0a8"), 2.5)
	draw_line(Vector2(0.0, 9.0), Vector2(0.0, 17.0), Color("4cae78"), 3.0)
	draw_circle(Vector2(-4.0, -3.0), 2.0, Color("fffbd6"))


func _activate() -> void:
	_active = true
	monitoring = true


func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group(&"player"):
		return
	if not GameState.grant_extra_life():
		return
	collected = true
	monitoring = false
	PocketSfx.play(self, 880.0, 0.16, -12.0, 360.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.16)
	tween.tween_property(self, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(queue_free)
