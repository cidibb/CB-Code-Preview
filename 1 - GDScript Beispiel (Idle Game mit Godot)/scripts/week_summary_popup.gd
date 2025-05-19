extends Panel

func show_summary(sub_change: int, happiness_change: int, feedback: String, cat_warning: String, feedback_msg: String):
	var subs_text := "Gained %d followers since last week" % sub_change if sub_change >= 0 else "Lost %d followers since last week" % abs(sub_change)
	var happiness_text := "Gained %d Happiness" % happiness_change if happiness_change >= 0 else "Lost %d Happiness" % abs(happiness_change)
	
	$VBoxContainer/StatSummary.text = "%s\n\n%s\n\nViewer Feedback: %s" % [subs_text, happiness_text, feedback]
	$VBoxContainer/FeedbackFlavorText.text = '\n"%s"\n' % feedback_msg
	$VBoxContainer/CatHealthWarning.text = "\n%s" % cat_warning
	
	show()
	get_parent().visible = true  

func _on_continue_pressed():
	get_parent().visible = false  
	get_tree().current_scene.show_day_popup()

func _ready():
	visible = false

func show_bean_donation_popup():
	var blocker := Control.new()
	blocker.name = "BeanDonationBlocker"
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.anchor_right = 1.0
	blocker.anchor_bottom = 1.0
	blocker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	blocker.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.5)
	dimmer.anchor_right = 1.0
	dimmer.anchor_bottom = 1.0
	dimmer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dimmer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	blocker.add_child(dimmer)

	var popup_scene = preload("res://assets/BeanDonationPopup.tscn")
	var popup = popup_scene.instantiate()
	popup.get_node("VBoxContainer/BeanLabel").text = "You've collected 100 bean cans.\nWould you like to donate these to permanently increase your follower gain rate?\nYou can donate again later by clicking your bean counter."

	popup.get_node("VBoxContainer/YesButton").pressed.connect(func():
		GameState.beans -= 100
		GameState.bean_boost_level += 1
		get_tree().root.get_node("Game").update_top_stats()
		blocker.queue_free()
	)

	popup.get_node("VBoxContainer/NoButton").pressed.connect(func():
		blocker.queue_free()
	)

	blocker.add_child(popup)
	add_child(blocker)
