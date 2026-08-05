class_name PocketPlayer
extends CharacterBody2D


@export var walk_speed := 180.0
@export var sprint_speed := 280.0
@export var ground_acceleration := 1500.0
@export var ground_deceleration := 1800.0
@export var air_acceleration := 900.0
@export var gravity := 1200.0
@export var jump_velocity := -520.0
@export_range(0, 3, 1) var max_air_jumps := 1
@export var maximum_fall_speed := 700.0
@export var short_hop_multiplier := 0.65
@export var air_jump_feedback_time := 0.16
@export var stomp_bounce_velocity := -280.0
@export var coyote_time := 0.10
@export var jump_buffer_time := 0.12

var facing := 1.0
var controls_enabled := true
var is_crouched := false

var _standing_shape: CollisionShape2D
var _crouching_shape: CollisionShape2D
var _ceiling_check: ShapeCast2D
var _camera: Camera2D
var _coyote_remaining := 0.0
var _jump_buffer_remaining := 0.0
var _air_jumps_remaining := 0
var _air_jump_feedback_remaining := 0.0
var _spawn_protected := false
var _protection_remaining := 0.0
var _previous_feet_y := 0.0
var _last_stomp_frame := -1000


func _ready() -> void:
	InputSetup.ensure_default_actions()
	add_to_group(&"player")
	collision_layer = 1 << 1
	collision_mask = 1 << 0
	floor_snap_length = 8.0
	floor_max_angle = deg_to_rad(48.0)
	_build_body()
	GameState.respawn_requested.connect(_on_respawn_requested)
	GameState.game_over.connect(_on_game_over)
	GameState.level_completed.connect(_on_level_completed)
	_reset_air_jumps()
	_previous_feet_y = global_position.y + 24.0
	queue_redraw()


func _physics_process(delta: float) -> void:
	if GameState.run_status != GameState.RunStatus.PLAYING or not controls_enabled:
		velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)
		if not is_on_floor():
			velocity.y = minf(velocity.y + gravity * delta, maximum_fall_speed)
		move_and_slide()
		_previous_feet_y = global_position.y + 24.0
		return

	if is_on_floor():
		_coyote_remaining = coyote_time
		_reset_air_jumps()
	else:
		_coyote_remaining = maxf(0.0, _coyote_remaining - delta)

	if Input.is_action_just_pressed(&"jump"):
		_jump_buffer_remaining = jump_buffer_time
	else:
		_jump_buffer_remaining = maxf(0.0, _jump_buffer_remaining - delta)

	var wants_crouch := Input.is_action_pressed(&"crouch") and is_on_floor()
	if wants_crouch:
		_set_crouched(true)
	elif is_crouched:
		_ceiling_check.force_shapecast_update()
		if not _ceiling_check.is_colliding():
			_set_crouched(false)

	var input_axis := Input.get_axis(&"move_left", &"move_right")
	if absf(input_axis) > 0.05:
		facing = signf(input_axis)
	var target_speed := input_axis * (sprint_speed if Input.is_action_pressed(&"sprint") else walk_speed)
	if is_crouched:
		target_speed *= 0.42
	var acceleration := ground_acceleration if is_on_floor() else air_acceleration
	if is_on_floor() and is_zero_approx(input_axis):
		acceleration = ground_deceleration
	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)

	if _jump_buffer_remaining > 0.0 and not is_crouched:
		var can_ground_jump := _coyote_remaining > 0.0
		var can_air_jump := not can_ground_jump and _air_jumps_remaining > 0
		if can_ground_jump or can_air_jump:
			velocity.y = jump_velocity
			_jump_buffer_remaining = 0.0
			_coyote_remaining = 0.0
			if can_air_jump:
				_air_jumps_remaining -= 1
				_air_jump_feedback_remaining = air_jump_feedback_time
				PocketSfx.play(self, 620.0, 0.11, -14.0, 260.0)
			else:
				PocketSfx.play(self, 440.0, 0.09, -16.0, 190.0)

	if Input.is_action_just_released(&"jump") and velocity.y < 0.0:
		velocity.y *= short_hop_multiplier

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, maximum_fall_speed)

	var was_rising := velocity.y < 0.0
	move_and_slide()
	if was_rising:
		_handle_ceiling_collisions()
	_previous_feet_y = global_position.y + 24.0
	queue_redraw()


func _process(delta: float) -> void:
	if _air_jump_feedback_remaining > 0.0:
		_air_jump_feedback_remaining = maxf(0.0, _air_jump_feedback_remaining - delta)
		queue_redraw()
	if _spawn_protected:
		_protection_remaining = maxf(0.0, _protection_remaining - delta)
		visible = int(_protection_remaining * 14.0) % 2 == 0
		if _protection_remaining <= 0.0:
			_spawn_protected = false
			visible = true


func _draw() -> void:
	var height := 30.0 if is_crouched else 48.0
	var top := 24.0 - height
	var body_color := Color("66e6b4")
	var shadow_color := Color("1d8d78")
	draw_rect(Rect2(-16.0, top, 32.0, height), body_color, true)
	draw_rect(Rect2(-16.0, 14.0, 32.0, 10.0), shadow_color, true)
	draw_circle(Vector2(facing * 7.0, top + 11.0), 3.0, Color("10213b"))
	draw_line(Vector2(-12.0, 24.0), Vector2(-12.0 - velocity.x * 0.025, 24.0), Color("b5ffe5"), 3.0)
	draw_line(Vector2(12.0, 24.0), Vector2(12.0 - velocity.x * 0.025, 24.0), Color("b5ffe5"), 3.0)
	if _air_jump_feedback_remaining > 0.0:
		var progress := 1.0 - _air_jump_feedback_remaining / maxf(air_jump_feedback_time, 0.001)
		var ring_color := Color(0.97, 0.89, 0.35, 1.0 - progress)
		draw_arc(Vector2.ZERO, 24.0 + progress * 12.0, 0.0, TAU, 24, ring_color, 3.0)


func apply_camera_bounds(bounds: Rect2i) -> void:
	_camera.limit_left = bounds.position.x
	_camera.limit_top = bounds.position.y
	_camera.limit_right = bounds.end.x
	_camera.limit_bottom = bounds.end.y
	_camera.reset_smoothing()


func teleport_to(target: Vector2, bounds: Rect2i) -> void:
	global_position = target
	velocity = Vector2.ZERO
	_reset_air_jumps()
	_air_jump_feedback_remaining = 0.0
	_previous_feet_y = global_position.y + 24.0
	apply_camera_bounds(bounds)


func resolve_enemy_contact(enemy: Node2D, stomp_plane_y: float) -> void:
	if not controls_enabled or _spawn_protected:
		return
	var valid_stomp := velocity.y > 40.0 and _previous_feet_y <= stomp_plane_y + 9.0
	if valid_stomp and enemy.has_method(&"receive_stomp"):
		var accepted: bool = enemy.call(&"receive_stomp")
		if accepted:
			_last_stomp_frame = Engine.get_physics_frames()
			velocity.y = stomp_bounce_velocity
			PocketSfx.play(self, 235.0, 0.08, -13.0, 160.0)
			return
	request_death()


func request_death() -> void:
	if not controls_enabled or _spawn_protected:
		return
	if Engine.get_physics_frames() == _last_stomp_frame:
		return
	controls_enabled = false
	velocity = Vector2.ZERO
	PocketSfx.play(self, 150.0, 0.22, -10.0, -85.0)
	GameState.request_player_death()


func _build_body() -> void:
	_standing_shape = CollisionShape2D.new()
	_standing_shape.name = "StandingShape"
	var standing_rectangle := RectangleShape2D.new()
	standing_rectangle.size = Vector2(32.0, 48.0)
	_standing_shape.shape = standing_rectangle
	add_child(_standing_shape)

	_crouching_shape = CollisionShape2D.new()
	_crouching_shape.name = "CrouchingShape"
	_crouching_shape.position = Vector2(0.0, 10.0)
	var crouching_rectangle := RectangleShape2D.new()
	crouching_rectangle.size = Vector2(32.0, 28.0)
	_crouching_shape.shape = crouching_rectangle
	_crouching_shape.disabled = true
	add_child(_crouching_shape)

	_ceiling_check = ShapeCast2D.new()
	_ceiling_check.name = "CeilingCheck"
	_ceiling_check.position = Vector2(0.0, -4.0)
	_ceiling_check.target_position = Vector2(0.0, -21.0)
	_ceiling_check.collision_mask = 1 << 0
	var overhead_rectangle := RectangleShape2D.new()
	overhead_rectangle.size = Vector2(28.0, 8.0)
	_ceiling_check.shape = overhead_rectangle
	add_child(_ceiling_check)

	_camera = Camera2D.new()
	_camera.name = "Camera2D"
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 8.0
	_camera.limit_smoothed = true
	_camera.drag_horizontal_enabled = true
	_camera.drag_left_margin = 0.34
	_camera.drag_right_margin = 0.34
	_camera.drag_vertical_enabled = true
	_camera.drag_top_margin = 0.22
	_camera.drag_bottom_margin = 0.28
	add_child(_camera)
	_camera.make_current()


func _set_crouched(value: bool) -> void:
	if is_crouched == value:
		return
	is_crouched = value
	_standing_shape.set_deferred("disabled", value)
	_crouching_shape.set_deferred("disabled", not value)
	queue_redraw()


func _reset_air_jumps() -> void:
	_air_jumps_remaining = max_air_jumps


func _handle_ceiling_collisions() -> void:
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		if collision.get_normal().y > 0.65:
			var collider := collision.get_collider()
			if collider != null and collider.has_method(&"hit_from_below"):
				collider.call_deferred(&"hit_from_below")


func _on_respawn_requested(position: Vector2) -> void:
	global_position = position
	velocity = Vector2.ZERO
	_reset_air_jumps()
	_air_jump_feedback_remaining = 0.0
	controls_enabled = true
	_spawn_protected = true
	_protection_remaining = 1.25
	visible = true
	_previous_feet_y = global_position.y + 24.0
	_camera.reset_smoothing()
	GameState.confirm_respawn()


func _on_game_over() -> void:
	controls_enabled = false


func _on_level_completed(_summary: Dictionary) -> void:
	controls_enabled = false
	velocity = Vector2.ZERO
