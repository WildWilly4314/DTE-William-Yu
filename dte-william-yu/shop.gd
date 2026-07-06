extends Control

signal shop_closed

var upgrades = {
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
	}
}

var upgrade_buttons = {}

func _ready():
	$ContinueButton.pressed.connect(_on_continue_pressed)
	build_upgrade_ui()
	refresh_ui()

func build_upgrade_ui():
	for key in upgrades:
		var data = upgrades[key]
		
		var container = HBoxContainer.new()
		
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

func get_cost(key):
	var data = upgrades[key]
	return int(data["base_cost"] * pow(data["cost_multiplier"], data["level"]))

func refresh_ui():
	var money = get_tree().get_root().get_node("Game").money
	for key in upgrades:
		var data = upgrades[key]
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
		upgrades[key]["level"] += 1
		apply_upgrade(key)
		refresh_ui()

func apply_upgrade(key):
	var level = upgrades[key]["level"]
	var tractor = get_tree().get_first_node_in_group("tractor")
	var player = get_tree().get_first_node_in_group("player")
	
	if key == "tractor_speed" and tractor:
		tractor.SPEED = 150.0 + (level * 30.0)
	elif key == "player_speed" and player:
		player.SPEED = 200.0 + (level * 30.0)
	elif key == "break_resistance" and tractor:
		tractor.BREAK_CHANCE_ON_HIT = max(0.0, 0.15 - (level * 0.025))

func _on_continue_pressed():
	emit_signal("shop_closed")
	queue_free()
