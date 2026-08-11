extends CharacterBody2D

var SPEED = 300.0
var BREAK_CHANCE_ON_HIT = 0.15
var REPAIR_WAIT_TIME = 5.0

const DASH_SPEED = 1200
const DASH_DURATION = 0.2
const DASH_COOLDOWN = 2.0

var player_inside = false
var player_ref = null
var is_broken = false
var repair_timer = 0.0
var can_repair = false

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = Vector2.ZERO

func _ready():
	$TimerLabel.visible = false

func _physics_process(delta):
	if is_broken:
		velocity = Vector2.ZERO
		move_and_slide()
		if not can_repair:
			repair_timer -= delta
			$TimerLabel.text = str(snapped(repair_timer, 0.01)) + "s"
			if repair_timer <= 0:
				can_repair = true
				$TimerLabel.text = "Press F to fix!"
		return

	if not player_inside:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if player_ref:
		player_ref.global_position = global_position

	# Count down dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# Count down active dash
	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * DASH_SPEED
		move_and_slide()
		if dash_timer <= 0:
			is_dashing = false
		return

	var input = Vector2.ZERO
	input.x = Input.get_axis("ui_left", "ui_right")
	input.y = Input.get_axis("ui_up", "ui_down")

	# Dash input
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		if input != Vector2.ZERO:
			dash_direction = input.normalized()
		else:
			dash_direction = Vector2.DOWN
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN
		# Visual feedback - flash white
		modulate = Color(1.5, 1.5, 1.5)
		await get_tree().create_timer(0.1).timeout
		if not is_broken:
			modulate = Color(1, 1, 1)
		return

	if input != Vector2.ZERO:
		input = input.normalized()
		velocity = input * SPEED
		update_animation(input)
	else:
		velocity = velocity.lerp(Vector2.ZERO, 0.2)

	move_and_slide()

func update_animation(dir: Vector2):
	var anim = $AnimatedSprite2D
	if dir.y < -0.5 and abs(dir.x) < 0.5:
		anim.play("up")
	elif dir.y > 0.5 and abs(dir.x) < 0.5:
		anim.play("down")
	elif dir.x < -0.5 and abs(dir.y) < 0.5:
		anim.play("left")
	elif dir.x > 0.5 and abs(dir.y) < 0.5:
		anim.play("right")
	elif dir.x < 0 and dir.y < 0:
		anim.play("top_left")
	elif dir.x > 0 and dir.y < 0:
		anim.play("top_right")
	elif dir.x < 0 and dir.y > 0:
		anim.play("bottom_left")
	elif dir.x > 0 and dir.y > 0:
		anim.play("bottom_right")

func enter(player):
	if is_broken:
		return
	player_inside = true
	player_ref = player
	player.visible = false
	player.set_physics_process(false)

func exit():
	player_inside = false
	if player_ref:
		player_ref.visible = true
		player_ref.set_physics_process(true)
		var exit_offset = -velocity.normalized() * 80
		if exit_offset == Vector2.ZERO:
			exit_offset = Vector2(-80, 0)
		player_ref.global_position = global_position + exit_offset
		player_ref = null
	velocity = Vector2.ZERO

func reset():
	if player_inside:
		exit()
	is_broken = false
	can_repair = false
	repair_timer = 0.0
	is_dashing = false
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	modulate = Color(1, 1, 1)
	$TimerLabel.visible = false

func break_down():
	if is_broken:
		return
	is_broken = true
	can_repair = false
	repair_timer = REPAIR_WAIT_TIME
	$TimerLabel.visible = true
	$TimerLabel.text = str(snapped(repair_timer, 0.01)) + "s"
	if player_inside:
		exit()
	modulate = Color(1, 0.3, 0.3)

func fix():
	if not can_repair:
		return
	is_broken = false
	can_repair = false
	repair_timer = 0.0
	$TimerLabel.visible = false
	modulate = Color(1, 1, 1)

func hit_by_vegetable():
	if is_broken:
		return
	if randf() < BREAK_CHANCE_ON_HIT:
		break_down()

func _on_enter_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.nearby_truck = self

func _on_enter_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.nearby_truck = null
