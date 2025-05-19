extends Area2D

var lifespan := randf_range(1.5, 3.0)
var wobble_timer := 0.0
var clicked := false 

@onready var sprite = $Sprite2D

func _ready():
	randomize()

	var scale_factor = randf_range(0.2, 1.0)
	sprite.scale = Vector2.ONE * scale_factor

	var screen_size = get_viewport_rect().size
	position = Vector2(
		randf_range(50, screen_size.x - 50),
		randf_range(50, screen_size.y - 50)
	)

	input_pickable = true
	set_process(true)

func _process(delta):
	wobble_timer += delta
	sprite.rotation = sin(wobble_timer * 10.0) * 0.1

	lifespan -= delta
	if lifespan <= 0:
		queue_free()

func _input_event(_viewport, event, _shape_idx):
	if clicked:
		return 

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked = true  
		GameState.beans += 1
		$wiwiwi.play()

		var popup = get_tree().root.get_node_or_null("Game/BeanPopup")
		if popup:
			popup.show_popup("BEANS COLLECTED!")

		var game = get_tree().root.get_node_or_null("Game")
		if game:
			game.update_top_stats()

			var float_label_scene = preload("res://assets/beanfloatlabel.tscn")
			var float_label = float_label_scene.instantiate()
			float_label.global_position = global_position
			game.add_child(float_label)
			float_label.show_and_fade()

		await $wiwiwi.finished
		queue_free()
