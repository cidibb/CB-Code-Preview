extends Window

var pending_action = ""

func show_action_confirmation(action: String):
	pending_action = action
	$MarginContainer/Label.text = "Do you want to %s today?\n" % action
	$MarginContainer/HBoxContainer/ButtonYes.show()
	$MarginContainer/HBoxContainer/ButtonNo.show()
	popup_centered()

func _on_button_yes_pressed():
	hide()
	$MarginContainer/HBoxContainer/ButtonYes.hide()
	$MarginContainer/HBoxContainer/ButtonNo.hide()
	get_tree().get_root().get_node("Game").finalize_action(pending_action)

func _on_button_no_pressed():
	hide()
	$MarginContainer/HBoxContainer/ButtonYes.hide()
	$MarginContainer/HBoxContainer/ButtonNo.hide()

func _ready():
	hide()
