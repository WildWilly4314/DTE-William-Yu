extends Control

signal shop_closed

var all_upgrades = {
	"tractor_speed": {
		"name": "Tractor Speed",
		"description": "+30 tractor speed",
		"level": 0,
		"max_level": 5,
		"base_cost": 50,
		"cost_multiplier": 1.5
	},
	"player_speed": {
		"name": "Player Speed",
		"description": "+30 movement speed",
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
		"description": "Veggies flee from further away",
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

	for key in todays_upgrades:
		var data = all_upgrades[key]

		# Outer card panel
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(180, 260)

		# Inner VBox
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 12)
		panel.add_child(vbox)

		# Upgrade name
		var name_label = Label.new()
		name_label.text = data["name"]
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(name_label)

		# Description
		var desc_label = Label.new()
		desc_label.text = data["description"]
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(desc_label)

		# Level label
		var level_label = Label.new()
		level_label.name = key + "_level"
		level_label.add_theme_font_size_override("font_size", 13)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(level_label)

		# Buy button
		var buy_button = Button.new()
		buy_button.name = key + "_button"
		buy_button.custom_minimum_size = Vector2(140, 50)
		buy_button.add_theme_font_size_override("font_size", 15)
		buy_button.pressed.connect(_on_buy_pressed.bind(key))
		vbox.add_child(buy_button)

		$UpgradeList.add_child(panel)
		upgrade_buttons[key] = {
			"level_label": level_label,
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
		var level_label = upgrade_buttons[key]["level_label"]
		var button = upgrade_buttons[key]["button"]

		if data["level"] >= data["max_level"]:
			level_label.text = "Level: MAX"
			button.text = "MAXED OUT"
			button.disabled = true
		else:
			level_label.text = "Level: " + str(data["level"]) + "/" + str(data["max_level"])
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
