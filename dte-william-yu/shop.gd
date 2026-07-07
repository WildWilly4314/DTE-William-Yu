extends Control

signal shop_closed

var all_upgrades = {
	"tractor_speed": {
		"name": "Tractor Speed",
		"description": "Go faster in the tractor",
		"level": 0,
		"max_level": 5,
		"base_cost": 50,
		"cost_multiplier": 1.5
	},
	"player_speed": {
		"name": "Player Speed",
		"description": "Move faster on foot",
		"level": 0,
		"max_level": 5,
		"base_cost": 30,
		"cost_multiplier": 1.5
	},
	"break_resistance": {
		"name": "Break Resistance",
		"description": "Tractor less likely to break",
		"level": 0,
		"max_level": 5,
		"base_cost": 75,
		"cost_multiplier": 2.0
	},
	"vegetable_flee_radius": {
		"name": "Vegetable Radar",
		"description": "Vegetables get scared from further away",
		"level": 0,
		"max_level": 5,
		"base_cost": 40,
		"cost_multiplier": 1.5
	},
	"repair_speed": {
		"name": "Repair Speed",
		"description": "Tractor repairs faster",
		"level": 0,
		"max_level": 5,
		"base_cost": 60,
		"cost_multiplier": 1.8
	}
}

var todays_upgrades = []
var upgrade_buttons = {}

func _ready():
	$ContinueButton.pressed.connect(_on_continue_pressed)
	pick_todays_upgrades()
	build_upgrade_ui()
	refresh_ui()

func pick_todays_upgrades():
	var keys = all_upgrades.keys()
	keys.shuffle()
	todays_upgrades = keys.slice(0, 3)

func get_cost(key):
	var data = all_upgrades[key]
	return int(data["base_cost"] * pow(data["cost_multiplier"], data["level"]))

func build_upgrade_ui():
	for child in $UpgradeList.get_children():
		child.queue_free()
	upgrade_buttons.clear()
	
	$TitleLabel.text = "Upgrades of the Day!"
	
	for key in todays_upgrades:
		var container = HBoxContainer.new()
		container.custom_minimum_size = Vector2(0, 60)
		
		var info_label = Label.new()
		info_label.name = key + "_label"
		info_label.custom_minimum_size = Vector2(300, 0)
		container.add_child(info_label)
		
		var buy_button = Button.new()
		buy_button.name = key + "_button"
		buy_button.custom_minimum_size = Vector2(150, 40)
		buy_button.pressed.connect(_on_buy_pressed.bind(key))
		container.add_child(buy_button)
		
		$UpgradeList.add_child(container)
		upgrade_buttons[key] = {
			"label": info_label,
			"button": buy_button
		}

func refresh_ui():
	var money = get_tree().get_root().get_node("Game").money
	$MoneyLabel.text = "Your Money: $" + str(money)
	
	for key in todays_upgrades:
		if not upgrade_buttons.has(key):
			continue
		var data = all_upgrades[key]
		var cost = get_cost(key)
		var label = upgrade_buttons[key]["label"]
		var button = upgrade_buttons[key]["button"]
		
		if data["level"] >= data["max_level"]:
			label.text = data["name"] + "\nLevel: MAX"
			button.text = "MAXED"
			button.disabled = true
		else:
			label.text = data["name"] + "\nLevel: " + str(data["level"]) + "/" + str(data["max_level"]) + "\n" + data["description"]
			button.text = "Buy - $" + str(cost)
			button.disabled = money < cost

func _on_buy_pressed(key):
	var game = get_tree().get_root().get_node("Game")
	var cost = get_cost(key)
	if game.money >= cost:
		game.add_money(-cost)
		all_upgrades[key]["level"] += 1
		apply_upgrade(key)
		refresh_ui()

func apply_upgrade(key):
	var level = all_upgrades[key]["level"]
	var tractor = get_tree().get_first_node_in_group("tractor")
	var player = get_tree().get_first_node_in_group("player")
	
	if key == "tractor_speed" and tractor:
		tractor.SPEED = 300.0 + (level * 30.0)
	elif key == "player_speed" and player:
		player.SPEED = 150.0 + (level * 30.0)
	elif key == "break_resistance" and tractor:
		tractor.BREAK_CHANCE_ON_HIT = max(0.0, 0.15 - (level * 0.025))
	elif key == "vegetable_flee_radius":
		get_tree().call_group("vegetable", "set_flee_radius", 200.0 + (level * 50.0))
	elif key == "repair_speed" and tractor:
		tractor.REPAIR_WAIT_TIME = max(1.0, 5.0 - (level * 0.8))

func new_day():
	pick_todays_upgrades()
	build_upgrade_ui()
	refresh_ui()

func _on_continue_pressed():
	new_day()
	emit_signal("shop_closed")
