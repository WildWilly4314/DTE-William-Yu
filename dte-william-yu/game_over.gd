extends Control

var final_day = 0
var final_money = 0

func _ready():
	$RestartButton.pressed.connect(_on_restart_pressed)

func set_stats(day: int, money: int):
	final_day = day
	final_money = money
	$TitleLabel.text = "GAME OVER"
	$ReasonLabel.text = "You survived " + str(day) + " days\nand earned $" + str(money) + " total!"

func _on_restart_pressed():
	get_tree().reload_current_scene()
