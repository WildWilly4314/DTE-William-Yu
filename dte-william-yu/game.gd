extends Node2D

var money = 90000
var day = 1
var day_length = 30
var day_timer = 0.0
var player_start_position = Vector2.ZERO
var tractor_start_position = Vector2.ZERO
var shop_open = false
var shop_instance = null
var selected_spawn = "default"

const BASE_MONEY_GOAL = 200
const DAY_CYCLE = 5

var vegetable_data = []

signal money_changed(new_amount)
signal day_changed(new_day)

var shop_scene = preload("res://shop.tscn")
var game_over_scene = preload("res://game_over.tscn")

func get_current_goal() -> int:
	return (int(day / DAY_CYCLE) + 1) * BASE_MONEY_GOAL

func _ready():
	$HUD/MoneyLabel.text = "MONEY $" + str(money)
	$HUD/DayLabel.text = "Day " + str(day)
	$HUD/DayTimerLabel.text = "60s"
	$HUD/BlackScreen.modulate.a = 0
	$HUD/BlackScreen.visible = true
	$HUD/DashLabel.text = ""
	update_goal_label()

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

func update_goal_label():
	if $HUD.has_node("GoalLabel"):
		var next_check = (int(day / DAY_CYCLE) + 1) * DAY_CYCLE
		var next_goal = (int(day / DAY_CYCLE) + 1) * BASE_MONEY_GOAL
		$HUD/GoalLabel.text = "Goal: $" + str(next_goal) + " by Day " + str(next_check)

func _process(delta):
	if shop_open:
		return
	day_timer += delta
	var time_left = day_length - day_timer
	$HUD/DayTimerLabel.text = str(snapped(time_left, 0.01)) + "s"
	if day_timer >= day_length:
		day_timer = 0.0
		advance_day()

	var tractor = get_tree().get_first_node_in_group("tractor")
	if tractor and tractor.player_inside:
		update_dash_label(tractor.dash_cooldown_timer, tractor.is_dashing)
	else:
		$HUD/DashLabel.text = ""

func update_dash_label(cooldown: float, dashing: bool):
	if dashing:
		$HUD/DashLabel.text = "DASHING!"
	elif cooldown > 0:
		$HUD/DashLabel.text = "Dash: " + str(snapped(cooldown, 0.1)) + "s"
	else:
		$HUD/DashLabel.text = "Dash: Ready!"

func advance_day():
	if day % DAY_CYCLE == 0:
		var goal = (int(day / DAY_CYCLE)) * BASE_MONEY_GOAL
		if money < goal:
			show_game_over()
			return
		else:
			add_money(-goal)
			show_payment_popup(goal)

	day += 1
	emit_signal("day_changed", day)
	$HUD/DayLabel.text = "Day " + str(day)
	update_goal_label()

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
	var tractor = get_tree().get_first_node_in_group("tractor")
	if tractor:
		tractor.set_physics_process(false)
	var vegetables = get_tree().get_nodes_in_group("vegetable")
	for veg in vegetables:
		veg.set_physics_process(false)

	var tween = create_tween()
	tween.tween_property($HUD/BlackScreen, "modulate:a", 1.0, 0.4)
	await tween.finished

	await respawn_all_vegetables()

	show_day_popup()
	await get_tree().create_timer(1.0).timeout

	open_shop()
	var tween2 = create_tween()
	tween2.tween_property($HUD/BlackScreen, "modulate:a", 0.0, 0.4)

func get_spawn_position() -> Vector2:
	match selected_spawn:
		"snow":
			if has_node("SnowSpawn"):
				return $SnowSpawn.global_position
			return Vector2(2500, 400)
		_:
			if has_node("DefaultSpawn"):
				return $DefaultSpawn.global_position
			return player_start_position

func get_tractor_spawn_position() -> Vector2:
	match selected_spawn:
		"snow":
			if has_node("SnowSpawn"):
				return $SnowSpawn.global_position + Vector2(100, 0)
			return Vector2(2600, 400)
		_:
			if has_node("DefaultSpawn"):
				return $DefaultSpawn.global_position + Vector2(100, 0)
			return tractor_start_position

func show_payment_popup(amount: int):
	var label = Label.new()
	label.text = "-$" + str(amount) + " (Day " + str(day) + " tax!)"
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	label.set_anchors_preset(Control.PRESET_CENTER)
	$HUD.add_child(label)
	var tween = create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -80), 1.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(label.queue_free)

func show_game_over():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
	var tractor = get_tree().get_first_node_in_group("tractor")
	if tractor:
		tractor.set_physics_process(false)
	var vegetables = get_tree().get_nodes_in_group("vegetable")
	for veg in vegetables:
		veg.set_physics_process(false)

	var tween = create_tween()
	tween.tween_property($HUD/BlackScreen, "modulate:a", 1.0, 0.5)
	await tween.finished

	var game_over = game_over_scene.instantiate()
	game_over.set_stats(day, money)
	$HUD.add_child(game_over)

func reset_all_positions():
	var spawn_pos = get_spawn_position()
	var tractor_pos = get_tractor_spawn_position()

	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.in_truck and player.nearby_truck:
			player.nearby_truck.exit()
		player.in_truck = false
		player.nearby_truck = null
		player.global_position = spawn_pos
		player.velocity = Vector2.ZERO

	var tractor = get_tree().get_first_node_in_group("tractor")
	if tractor:
		tractor.global_position = tractor_pos
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

func respawn_single_vegetable(scene_path: String, pos: Vector2, money_val: int, flee_spd: float):
	var scene = load(scene_path)
	if scene:
		var veg = scene.instantiate()
		veg.global_position = pos
		veg.money_value = money_val
		veg.flee_speed = flee_spd
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

	# Reset positions AFTER shop closes so spawn choice is applied
	reset_all_positions()

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
	var tractor = get_tree().get_first_node_in_group("tractor")
	if tractor:
		tractor.set_physics_process(true)
	var vegetables = get_tree().get_nodes_in_group("vegetable")
	for veg in vegetables:
		veg.set_physics_process(true)

func unlock_field(key: String):
	if key == "field2":
		var field = $Field2
		field.get_node("ColorRect").visible = false
		if field.has_node("LockWall"):
			field.get_node("LockWall").queue_free()

func add_money(amount):
	money += amount
	emit_signal("money_changed", money)
	$HUD/MoneyLabel.text = "MONEY $" + str(money)
