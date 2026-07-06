extends Node2D

var money = 0
var day = 1
var day_length = 60.0
var day_timer = 0.0
var player_start_position = Vector2.ZERO
var shop_open = false

signal money_changed(new_amount)
signal day_changed(new_day)

var shop_scene = preload("res://shop.tscn")

func _ready():
	$HUD/MoneyLabel.text = "MONEY $" + str(money)
	$HUD/DayLabel.text = "Day " + str(day)
	$HUD/DayTimerLabel.text = "60s"
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_start_position = player.global_position

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
	show_day_popup()
	reset_player_position()
	open_shop()

func reset_player_position():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = player_start_position

func show_day_popup():
	var popup_scene = preload("res://day_popup.tscn")
	var popup = popup_scene.instantiate()
	popup.set_day_text("Day " + str(day))
	$HUD.add_child(popup)

func open_shop():
	shop_open = true
	var shop = shop_scene.instantiate()
	shop.shop_closed.connect(_on_shop_closed)
	$HUD.add_child(shop)
	# Pause player and tractor
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
	var tractor = get_tree().get_first_node_in_group("tractor")
	if tractor:
		tractor.set_physics_process(false)

func _on_shop_closed():
	shop_open = false
	# Unpause player and tractor
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
	var tractor = get_tree().get_first_node_in_group("tractor")
	if tractor:
		tractor.set_physics_process(true)

func add_money(amount):
	money += amount
	emit_signal("money_changed", money)
	$HUD/MoneyLabel.text = "MONEY $" + str(money)
