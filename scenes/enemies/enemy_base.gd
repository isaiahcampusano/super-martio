class_name PocketEnemy
extends CharacterBody2D


@export var speed := 70.0
@export var gravity := 1200.0
@export var body_size := Vector2(36.0, 32.0)
@export var maximum_health := 1
@export var turns_at_edges := false
@export var body_color := Color("bc6cff")
@export var defeat_time_bonus := 2.0

var direction := -1.0
var health := 1
var _floor_check: RayCast2D
var _contact_area: Area2D
var _can_be_stomped := true


func _ready() -> void:
	add_to_group(&"enemy")
	collision_layer = 1 << 2
	collision_mask = 1 << 0
	health = maximum_health
	_build_body()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if GameState.run_status != GameState.RunStatus.PLAYING:
		return
	velocity.x = direction * speed
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 720.0)
	move_and_slide()
	_update_floor_check()
	var should_turn := is_on_wall()
	if turns_at_edges and is_on_floor():
		_floor_check.force_raycast_update()
		should_turn = should_turn or not _floor_check.is_colliding()
	if should_turn:
		direction *= -1.0
		_update_floor_check()
		queue_redraw()


func receive_stomp() -> bool:
	if not _can_be_stomped or health <= 0:
		return false
	_can_be_stomped = false
	health -= 1
	PocketSfx.play(self, 190.0 if health > 0 else 120.0, 0.09, -17.0, -40.0)
	if health <= 0:
		GameState.award_enemy_time_bonus(defeat_time_bonus)
		collision_layer = 0
		_contact_area.set_deferred("monitoring", false)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(1.25, 0.15), 0.16)
		tween.tween_property(self, "modulate:a", 0.0, 0.16)
		tween.chain().tween_callback(queue_free)
	else:
		direction *= -1.0
		modulate = Color("fff0a8")
		var tween := create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.18)
		tween.tween_callback(_reset_stomp_cooldown)
	return true


func get_stomp_plane_y() -> float:
	return global_position.y - body_size.y * 0.5 + 7.0


func _build_body() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = body_size
	collision.shape = shape
	add_child(collision)

	_contact_area = Area2D.new()
	_contact_area.name = "ContactArea"
	_contact_area.collision_layer = 1 << 3
	_contact_area.collision_mask = 1 << 1
	_contact_area.monitoring = true
	_contact_area.monitorable = true
	var contact_collision := CollisionShape2D.new()
	var contact_shape := RectangleShape2D.new()
	contact_shape.size = body_size + Vector2(8.0, 6.0)
	contact_collision.shape = contact_shape
	_contact_area.add_child(contact_collision)
	_contact_area.body_entered.connect(_on_body_entered)
	add_child(_contact_area)

	_floor_check = RayCast2D.new()
	_floor_check.name = "FloorCheck"
	_floor_check.target_position = Vector2(0.0, body_size.y * 0.5 + 16.0)
	_floor_check.collision_mask = 1 << 0
	_floor_check.enabled = true
	add_child(_floor_check)
	_update_floor_check()


func _update_floor_check() -> void:
	if _floor_check != null:
		_floor_check.position = Vector2(direction * (body_size.x * 0.5 + 5.0), 0.0)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method(&"resolve_enemy_contact"):
		body.call(&"resolve_enemy_contact", self, get_stomp_plane_y())


func _reset_stomp_cooldown() -> void:
	_can_be_stomped = true


func _draw() -> void:
	var rect := Rect2(-body_size * 0.5, body_size)
	draw_rect(rect, body_color, true)
	draw_rect(Rect2(rect.position + Vector2(0.0, body_size.y - 8.0), Vector2(body_size.x, 8.0)), body_color.darkened(0.35), true)
	var eye_x := direction * 8.0
	draw_circle(Vector2(eye_x, -5.0), 3.5, Color("11192d"))
	if maximum_health > 1:
		draw_line(Vector2(-10.0, -body_size.y * 0.5 - 5.0), Vector2(10.0, -body_size.y * 0.5 - 5.0), Color("18233d"), 5.0)
		draw_line(Vector2(-10.0, -body_size.y * 0.5 - 5.0), Vector2(-10.0 + 20.0 * float(health) / float(maximum_health), -body_size.y * 0.5 - 5.0), Color("ff6b72"), 3.0)
