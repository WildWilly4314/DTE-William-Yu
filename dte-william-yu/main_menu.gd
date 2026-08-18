extends Control

func _ready():
	$VideoStreamPlayer.paused = true
	$StartButton.pressed.connect(_on_start_pressed)
	$ExitButton.pressed.connect(_on_exit_pressed)
	$PlayVideoButton.pressed.connect(_on_play_video_pressed)

func _on_play_video_pressed():
	if $VideoStreamPlayer.is_playing():
		$VideoStreamPlayer.paused = true
		$PlayVideoButton.text = "▶"
	else:
		$VideoStreamPlayer.paused = false
		$VideoStreamPlayer.play()
		$PlayVideoButton.text = "⏸"

func _on_start_pressed():
	get_tree().change_scene_to_file("res://game.tscn")

func _on_exit_pressed():
	get_tree().quit()
