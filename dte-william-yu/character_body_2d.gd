extends CharacterBody2D

const SPEED = 150
var nearby_truck = null
var in_truck = false

func _physics_process(delta):
	if in_truck:
		if nearby_truck == null or not nearby_truck.player_inside:
			in_truck = false
		return
	
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
		anim.play("walk_up")
	elif dir.y > 0.5 and abs(dir.x) < 0.5:
		anim.play("walk_down")
	elif dir.x < 0:
		anim.play("walk_left")
	elif dir.x > 0:
		anim.play("walk_right")

func _input(event):
	if event.is_action_pressed("enter_vehicle"):
		if nearby_truck and not in_truck:
			if nearby_truck.is_broken:
				nearby_truck.fix()
			else:
				nearby_truck.enter(self)
				in_truck = true
		elif in_truck and nearby_truck:
			nearby_truck.exit()
			in_truck = false
			nearby_truck = null
