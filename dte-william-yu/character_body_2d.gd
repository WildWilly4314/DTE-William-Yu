extends CharacterBody2D

var SPEED = 150.0
var nearby_truck = null
var in_truck = false
var last_direction = "down"

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
		stop_animation()
	
	move_and_slide()

func update_animation(dir: Vector2):
	var anim = $AnimatedSprite2D
	if dir.y < -0.5 and abs(dir.x) < 0.5:
		anim.play("walk_up")
		last_direction = "up"
	elif dir.y > 0.5 and abs(dir.x) < 0.5:
		anim.play("walk_down")
		last_direction = "down"
	elif dir.x < 0:
		anim.play("walk_left")
		last_direction = "left"
	elif dir.x > 0:
		anim.play("walk_right")
		last_direction = "right"

func stop_animation():
	var anim = $AnimatedSprite2D
	anim.stop()
	anim.play("walk_" + last_direction)
	anim.frame = 1

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
