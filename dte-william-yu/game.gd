extends Node2D

var money = 0
var day = 1
var day_length = 30
var day_timer = 0.0
var player_start_position = Vector2.ZERO
var tractor_start_position = Vector2.ZERO
var shop_open = false
var shop_instance = null

var vegetable_data = []

signal money_changed(new_amount)
signal day_changed(new_day)

var shop_scene = preload("res://shop.tscn")

func _ready():
	$HUD/MoneyLabel.text = "MONEY $" + str(money)
	$HUD/DayLabel.text = "Day " + str(day)
	$HUD/DayTimerLabel.text = "60s"
	$HUD/BlackScreen.modulate.a = 0
	$HUD/BlackScreen.visible = true
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_start_position = player.global_position
	
	var tractor = get_tree().get_first_node_in_group("tractor")
	if tractor:
		tractor_start_position = tractor.global_position
	
	var vegetables = get_tree().get_nodes_in_group("vegetable")
	for veg in vegetables:
		vegetable_data.append({
			"scene": veg.scene_file_path,
			"position": veg.global_position
		})
	
	shop_instance = shop_scene.instantiate()
	shop_instance.shop_closed.connect(_on_shop_closed)
	shop_instance.visible = false
	$HUD.add_child(shop_instance)

func _process(delta):
	if shop_open:
		return
	day_timer += delta
	var time_left = day_length - day_timer
	$HUD/DayTimerLabel.text = str(snapped(time_left, 0.01)) + "s"
	if day_timer >= day_length:
		day_timer = 0.0
		advance_day()

func advance_day():
	day += 1
	emit_signal("day_changed", day)
	$HUD/DayLabel.text = "Day " + str(day)
	
	# Pause everything immediately
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
	var tractor = get_tree().get_first_node_in_group("tractor")
	if tractor:
		tractor.set_physics_process(false)
	var vegetables = get_tree().get_nodes_in_group("vegetable")
	for veg in vegetables:
		veg.set_physics_process(false)
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property($HUD/BlackScreen, "modulate:a", 1.0, 0.4)
	await tween.finished
	
	# Reset everything while screen is black
	reset_all_positions()
	await respawn_all_vegetables()
	
	# Show day popup over black screen
	show_day_popup()
	await get_tree().create_timer(1.0).timeout
	
	# Fade black screen out to reveal shop
	open_shop()
	var tween2 = create_tween()
	tween2.tween_property($HUD/BlackScreen, "modulate:a", 0.0, 0.4)

func reset_all_positions():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.in_truck and player.nearby_truck:
			player.nearby_truck.exit()
		player.in_truck = false
		player.nearby_truck = null
		player.global_position = player_start_position
		player.velocity = Vector2.ZERO
	
	var tractor = get_tree().get_first_node_in_group("tractor")
	if tractor:
		tractor.global_position = tractor_start_position
		tractor.velocity = Vector2.ZERO
		tractor.reset()

func respawn_all_vegetables():
	var existing = get_tree().get_nodes_in_group("vegetable")
	for veg in existing:
		veg.queue_free()
	
	await get_tree().process_frame
	
	for data in vegetable_data:
		spawn_vegetable(data["scene"], data["position"])

func spawn_vegetable(scene_path: String, pos: Vector2):
	var scene = load(scene_path)
	if scene:
		var veg = scene.instantiate()
		veg.global_position = pos
		add_child(veg)

func show_day_popup():
	var popup_scene = preload("res://day_popup.tscn")
	var popup = popup_scene.instantiate()
	popup.set_day_text("Day " + str(day))
	$HUD.add_child(popup)

func open_shop():
	shop_open = true
	shop_instance.visible = true
	shop_instance.refresh_ui()

func _on_shop_closed():
	shop_open = false
	shop_instance.visible = false
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
	var tractor = get_tree().get_first_node_in_group("tractor")
	if tractor:
		tractor.set_physics_process(true)
	var vegetables = get_tree().get_nodes_in_group("vegetable")
	for veg in vegetables:
		veg.set_physics_process(true)

func add_money(amount):
	money += amount
	emit_signal("money_changed", money)
	$HUD/MoneyLabel.text = "MONEY $" + str(money)
