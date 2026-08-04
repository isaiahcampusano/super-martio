class_name PocketMovingPlatform
extends AnimatableBody2D


@export var platform_size := Vector2(128.0, 22.0)
@export var motion_vector := Vector2(240.0, 0.0)
@export var travel_time := 3.2
@export var phase_offset := 0.0

var _origin := Vector2.ZERO
var _time := 0.0


func _ready() -> void:
	collision_layer = 1 << 0
	collision_mask = 0
	sync_to_physics = true
	_origin = position
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = platform_size
	collision.shape = shape
	add_child(collision)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_time += delta
	var progress := (sin((_time / travel_time) * TAU + phase_offset) + 1.0) * 0.5
	position = _origin + motion_vector * progress


func _draw() -> void:
	draw_rect(Rect2(-platform_size * 0.5, platform_size), Color("4bc0c8"), true)
	draw_rect(Rect2(-platform_size * 0.5, Vector2(platform_size.x, 5.0)), Color("99f2da"), true)
	for x in range(int(-platform_size.x * 0.5 + 14.0), int(platform_size.x * 0.5), 24):
		draw_circle(Vector2(float(x), 4.0), 3.0, Color("1c6972"))

