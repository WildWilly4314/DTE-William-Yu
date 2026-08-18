extends Control

var final_day = 0
var final_money = 0

func _ready():
	$RestartButton.pressed.connect(_on_restart_pressed)

func set_stats(day: int, money: int):
	final_day = day
	final_money = money
	
	$TitleLabel.text = "GAME OVER"
	$ReasonLabel.text = "You made it to Day " + str(day) + "\nTotal earned: $" + str(money)
	
	var high_score = load_high_score()
	if day > high_score:
		save_high_score(day)
		$HighScoreLabel.text = "NEW HIGH SCORE! 🎉 Day " + str(day)
	else:
		$HighScoreLabel.text = "Best: Day " + str(high_score)

func save_high_score(day: int):
	var file = FileAccess.open("user://highscore.save", FileAccess.WRITE)
	file.store_32(day)
	file.close()

func load_high_score() -> int:
	if not FileAccess.file_exists("user://highscore.save"):
		return 0
	var file = FileAccess.open("user://highscore.save", FileAccess.READ)
	var score = file.get_32()
	file.close()
	return score

func _on_restart_pressed():
	get_tree().reload_current_scene()
