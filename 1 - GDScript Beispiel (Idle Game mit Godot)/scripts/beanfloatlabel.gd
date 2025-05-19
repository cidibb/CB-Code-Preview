extends Node2D

@onready var label = $Label

func show_and_fade():
	label.visible = true
	label.modulate.a = 1.0

	var tween = get_tree().create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)
