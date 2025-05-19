extends Window

func _on_button_pressed():
	hide()
	get_parent().get_node("ClickBlocker").visible = false
	get_parent().get_parent().show_day_popup() 

func show_results():
	$VBoxContainer/Label.text = "Raven chose to %s" % GameState.choice
	GameState.reset_choice()
	show()
	get_parent().get_node("ClickBlocker").visible = true
