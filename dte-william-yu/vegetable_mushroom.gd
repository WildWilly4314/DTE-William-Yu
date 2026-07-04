extends CharacterBody2D

const SPEED = 170
const FLEE_RADIUS = 200.0
const WANDER_SPEED = 60.0
const WANDER_CHANGE_TIME = 2.0

@export var money_value = 30
@export var flee_speed = 120.0

var player = null
var dead = false
var wander_direction = Vector2.ZERO
var wander_timer = 0.0

var popup_scene = preload("res://money_popup.tscn")

func _ready():
	player = get_tree().get_first_node_in_group("player")
	randomize()
	pick_new_wander_direction()

func pick_new_wander_direction():
	var angle = randf() * TAU
	wander_direction = Vector2(cos(angle), sin(angle))
	wander_timer = WANDER_CHANGE_TIME

func _physics_process(delta):
	if dead or player == null:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	var tractor = get_tree().get_first_node_in_group("tractor")
	var distance_to_tractor = INF
	if tractor:
		distance_to_tractor = global_position.distance_to(tractor.global_position)
	
	var should_flee = distance_to_player < FLEE_RADIUS or distance_to_tractor < FLEE_RADIUS
	
	if should_flee:
		var flee_from = player.global_position
		if tractor and distance_to_tractor < distance_to_player:
			flee_from = tractor.global_position
		var flee_direction = (global_position - flee_from).normalized()
		velocity = flee_direction * flee_speed
		update_animation(flee_direction)
	else:
		wander_timer -= delta
		if wander_timer <= 0:
			pick_new_wander_direction()
		velocity = wander_direction * WANDER_SPEED
		update_animation(wander_direction)
	
	move_and_slide()

func update_animation(dir: Vector2):
	var anim = $AnimatedSprite2D
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			anim.play("left")
			anim.flip_h = true
		else:
			anim.play("left")
			anim.flip_h = false
	else:
		anim.flip_h = false
		if dir.y > 0:
			anim.play("down")
		else:
			anim.play("up")

func die():
	if dead:
		return
	dead = true
	velocity = Vector2.ZERO
	
	$AnimatedSprite2D.play("explosion")
	
	get_tree().get_root().get_node("Game").add_money(money_value)
	
	var tractor = get_tree().get_first_node_in_group("tractor")
	print("Tractor found: ", tractor)
	if tractor:
		print("Calling hit_by_vegetable, break chance: ", tractor.BREAK_CHANCE_ON_HIT)
		tractor.hit_by_vegetable()
	
	var popup = popup_scene.instantiate()
	popup.global_position = global_position + Vector2(0, -30)
	get_parent().add_child(popup)
	
	await $AnimatedSprite2D.animation_finished
	queue_free()

func _on_hit_zone_body_entered(body):
	if body == self:
		return
	if body.is_in_group("player") or body.name == "Tractor":
		die()
