extends Control

var steps: Array = []
var current_index: int = 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	$CanvasLayer.process_mode = Node.PROCESS_MODE_ALWAYS
	$CanvasLayer.visible = false
	visible = false
	$CanvasLayer/NextButton.pressed.connect(_on_next_pressed)
	if has_node("CanvasLayer/SkipButton"):
		$CanvasLayer/SkipButton.pressed.connect(_on_skip_pressed)
	get_tree().root.child_entered_tree.connect(_on_scene_changed)

func _on_scene_changed(node):
	if node.name == "Game":
		await get_tree().process_frame
		if has_seen_tutorial():
			return
		start_tutorial(node)

func start_tutorial(game_node):
	steps = get_tutorial_steps(game_node)
	current_index = 0
	visible = true
	$CanvasLayer.visible = true
	get_tree().paused = true
	show_step()

func get_tutorial_steps(game_node) -> Array:
	var day_length_text = "30"
	if game_node and "day_length" in game_node:
		day_length_text = str(game_node.day_length)

	return [
		{
			"title": "Welcome to the Farm!",
			"text": "Use the arrow keys (or WASD) to walk around your field."
		},
		{
			"title": "Harvest Vegetables",
			"text": "Walk into a vegetable to harvest it for cash. They'll flee once you get close, so try to corner them!"
		},
		{
			"title": "Hop in the Tractor",
			"text": "Walk up to the tractor and press F to drive it. It's faster than walking and plows through veggies easily."
		},
		{
			"title": "Dash!",
			"text": "While driving, press Shift to dash forward and close the gap on fast runners. Watch the cooldown 
			crashing too much can break the tractor down."
		},
		{
			"title": "Beat the Clock",
			"text": "You have " + day_length_text + " seconds each day. Hit the money goal shown at the top before the deadline
			or it's game over."
		},
		{
			"title": "Shop Smart",
			"text": "At the end of each day, spend your earnings on upgrades and 
			unlock the Snow Biome for new areas to farm."
		}
	]

func show_step():
	var step = steps[current_index]
	$CanvasLayer/TitleLabel.text = step["title"]
	$CanvasLayer/BodyLabel.text = step["text"]

	if has_node("CanvasLayer/StepIndicatorLabel"):
		$CanvasLayer/StepIndicatorLabel.text = str(current_index + 1) + " / " + str(steps.size())

	$CanvasLayer/NextButton.text = "Got it!" if current_index == steps.size() - 1 else "Next"

func _on_next_pressed():
	current_index += 1
	if current_index >= steps.size():
		_finish()
	else:
		show_step()

func _on_skip_pressed():
	_finish()

func _finish():
	visible = false
	$CanvasLayer.visible = false
	get_tree().paused = false
	mark_tutorial_seen()

func has_seen_tutorial() -> bool:
	return FileAccess.file_exists("user://tutorial_seen.save")

func mark_tutorial_seen():
	var file = FileAccess.open("user://tutorial_seen.save", FileAccess.WRITE)
	file.store_8(1)
	file.close()
