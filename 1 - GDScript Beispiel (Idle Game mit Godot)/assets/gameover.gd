extends Control

func _ready():
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		delete_save_and_return_to_menu()

func delete_save_and_return_to_menu():
	var save_path = "user://savegame.json"
	if FileAccess.file_exists(save_path):
		var dir := DirAccess.open("user://")
		if dir:
			dir.remove("savegame.json")

	call_deferred("_return_to_main_menu")

func _return_to_main_menu():
	get_tree().change_scene_to_file("res://assets/Main.tscn")
