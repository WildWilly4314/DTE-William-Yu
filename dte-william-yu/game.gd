extends Node2D

var money = 0
var day = 1
var day_length = 60.0
var day_timer = 0.0
var player_start_position = Vector2.ZERO

signal money_changed(new_amount)
signal day_changed(new_day)

func _ready():
	$HUD/MoneyLabel.text = "MONEY $" + str(money)
	$HUD/DayLabel.text = "Day " + str(day)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_start_position = player.global_position

func _process(delta):
	day_timer += delta
	if day_timer >= day_length:
		day_timer = 0.0
		advance_day()

func advance_day():
	day += 1
	emit_signal("day_changed", day)
	$HUD/DayLabel.text = "Day " + str(day)
	show_day_popup()
	reset_player_position()

func reset_player_position():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = player_start_position

func show_day_popup():
	var popup_scene = preload("res://day_popup.tscn")
	var popup = popup_scene.instantiate()
	popup.set_day_text("Day " + str(day))
	$HUD.add_child(popup)

func add_money(amount):
	money += amount
	emit_signal("money_changed", money)
	$HUD/MoneyLabel.text = "MONEY $" + str(money)
