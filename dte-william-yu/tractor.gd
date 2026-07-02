extends CharacterBody2D

const SPEED = 300
var player_inside = false
var player_ref = null

func _physics_process(delta):
	if not player_inside:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if player_ref:
		player_ref.global_position = global_position
	
	var input = Vector2.ZERO
	input.x = Input.get_axis("ui_left", "ui_right")
	input.y = Input.get_axis("ui_up", "ui_down")
	
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
	player_inside = true
	player_ref = player
	player.visible = false
	player.set_physics_process(false)

func exit():
	player_inside = false
	player_ref.visible = true
	player_ref.set_physics_process(true)
	player_ref.global_position = global_position + Vector2(60, 0)
	player_ref = null
	velocity = Vector2.ZERO

func _on_enter_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.nearby_truck = self

func _on_enter_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.nearby_truck = null
