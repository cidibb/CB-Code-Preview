extends Label

func show_popup(message: String):
	text = message
	visible = true
	modulate.a = 1.0

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.2)
	tween.tween_callback(func(): visible = false)
