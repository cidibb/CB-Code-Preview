extends Button

func _ready():
	gui_input.connect(_on_back_to_menu_clicked)

func _on_back_to_menu_clicked(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file("res://assets/Main.tscn")
