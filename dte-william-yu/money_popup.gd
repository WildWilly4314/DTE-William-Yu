extends Node2D

func _ready():
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(0, -50), 0.8)
	tween.tween_callback(queue_free)
