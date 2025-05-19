extends Control

@onready var label_day_info = $VBoxContainer/TopMenuPanel/VBoxContainer/LabelDayInfo
@onready var day_label = $DayStartPopup/CenterContainer/Label
@onready var week_summary_popup_layer = $WeekSummaryPopupLayer
@onready var week_summary_popup = $WeekSummaryPopupLayer/WeekSummaryPopup
@onready var week_summary_layer = $WeekSummaryPopupLayer

@onready var label_beans = $VBoxContainer/TopMenuPanel/VBoxContainer/LabelBeans
@onready var label_twitch = $VBoxContainer/TopMenuPanel/VBoxContainer/LabelTwitch
@onready var label_happiness = $VBoxContainer/TopMenuPanel/VBoxContainer/LabelHappiness
@onready var label_feedback = $VBoxContainer/TopMenuPanel/VBoxContainer/LabelFeedback

@onready var slide_panel = $SlidePanel
@onready var menu_button = $SlidePanel/MenuButton

var sub_timer: Timer = null
var bean_timer: Timer
var bean_rate_boost_timer: Timer
var menu_open := false

func _boost_happiness_and_content():
	GameState.raven_happiness += 10
	GameState.content_quality += 5.0

var RANDOM_EVENTS = {
	"Work on your Charisma": [
		{
			"title": "You went to an open Mic night!",
			"description": "You did an impromptu bit at a local comedy club and everyone loved it.",
			"outcome": "You gained 50 followers.",
			"condition": func(): return GameState.charisma >= 50,
			"effect": func(): GameState.twitch_subs += 50
		},
		{
			"title": "You went to an open Mic night!",
			"description": "You blanked mid-sentence and stumbled off stage. Lowkey embarrassing.",
			"outcome": "You lost 10 happiness.",
			"condition": func(): return GameState.charisma < 50,
			"effect": func(): GameState.raven_happiness -= 10
		}
	],

	"Prepare New Content": [
		{
			"title": "You spent the day thinking of a new format.",
			"description": "You cracked the perfect structure for your next series.",
			"outcome": "+5 content quality.",
			"condition": func(): return GameState.content_quality >= 50,
			"effect": func(): GameState.content_quality += 5.0
		},
		{
			"title": "You spent the day thinking of a new format.",
			"description": "You sat at your desk for hours but made no progress.",
			"outcome": "-10 happiness.",
			"condition": func(): return GameState.content_quality < 50,
			"effect": func(): GameState.raven_happiness -= 10
		}
	],

	"Take Care of your Cats": [
		{
			"title": "OMG Peepers just did a backflip.",
			"description": "Thankfully you were recording and were able to post the clip, which went viral.",
			"outcome": "You gained 80 followers.",
			"condition": func(): return GameState.content_quality >= 40,
			"effect": func(): GameState.twitch_subs += 80
		},
		{
			"title": "Stormie decided that today is cuddle day.",
			"description": "She curled up on your lap while you edited.",
			"outcome": "+10 happiness.",
			"condition": func(): return true,
			"effect": func(): GameState.raven_happiness += 10
		}
	],

	"Maintain your Social Media": [
		{
			"title": "You came up with a funny tweet in the middle of the night.",
			"description": "It somehow went viral in a different time zone. Unexpected, but we take those.",
			"outcome": "You gained 60 followers.",
			"condition": func(): return GameState.online_presence >= 50,
			"effect": func(): GameState.twitch_subs += 60
		},
		{
			"title": "Instagram bugged and somehow wiped your follower count for 12 hours",
			"description": "You panicked and spammed your feed in the process. People did not like that.",
			"outcome": "-25 feedback score.",
			"condition": func(): return GameState.online_presence < 50,
			"effect": func(): GameState.feedback_score -= 25
		}
	],

	"Post a New Video": [
		{
			"title": "You posted a new video today.",
			"description": "It was picked up by the algorithm and hit trending.",
			"outcome": "You gained 150 followers.",
			"condition": func(): return GameState.content_quality >= 70,
			"effect": func(): GameState.twitch_subs += 150
		},
		{
			"title": "You posted a hot take video.",
			"description": "Viewers are arguing in your comments section and the weirdos reflect on you.",
			"outcome": "-10 feedback score.",
			"condition": func(): return GameState.charisma < 40,
			"effect": func(): GameState.feedback_score -= 10
		}
	],

	"Go Live on Twitch": [
		{
			"title": "OMG... CaseOh raided your stream!",
			"description": "Your high charisma captivated chat",
			"outcome": "— you gained 120 new followers!",
			"condition": func(): return GameState.charisma >= 70,
			"effect": func(): GameState.twitch_subs += 120
		},
		{
			"title": "OMG... CaseOh raided your stream!",
			"description": "You were flustered but made it through okay.",
			"outcome": "— you gained 60 new followers.",
			"condition": func(): return GameState.charisma >= 40 and GameState.charisma < 70,
			"effect": func(): GameState.twitch_subs += 60
		},
		{
			"title": "OMG... CaseOh raided your stream!",
			"description": "But you kinda fumbled...",
			"outcome": "Only gained 25 new followers.",
			"condition": func(): return GameState.charisma < 40,
			"effect": func(): GameState.twitch_subs += 25
		},
		{
			"title": "Someone donated 100 beans live on stream!",
			"description": "DID SOMEONE SAY BEANS?!",
			"outcome": "Bean spawn rate increased for 30 seconds.",
			"condition": func(): return true,
			"effect": func(): boost_bean_rate_for_seconds(30)
		}
	],

	"Take a Break": [
		{
			"title": "You walked through the park and listened to calming music.",
			"description": "Taking a break was a good idea. You feel much better.",
			"outcome": "+10 happiness, +5 content quality.",
			"condition": func(): return true,
			"effect": _boost_happiness_and_content
		},
		{
			"title": "You open up instagram before taking a break.",
			"description": "You meant to rest, but spent all day doomscrolling.",
			"outcome": "-5 happiness.",
			"condition": func(): return GameState.online_presence < 40,
			"effect": func(): GameState.raven_happiness -= 5
		}
	]
}

func is_any_popup_open() -> bool:
	return $ConfirmationPopupLayer/ConfirmationPopup.visible or week_summary_layer.visible

func _ready():
	load_game()
	update_day_label()
	update_top_stats()
	show_day_popup()
	start_subscriber_timer()
	$DayStartPopup.visible = false

	bean_timer = Timer.new()
	bean_timer.wait_time = 5.0
	bean_timer.one_shot = false
	bean_timer.timeout.connect(_try_spawn_bean)
	add_child(bean_timer)
	bean_timer.start()

	$VBoxContainer/BottomActionMenu/TextureButtonCharisma.pressed.connect(func(): _on_button_pressed("Work on your Charisma"))
	$VBoxContainer/BottomActionMenu/TextureButtonContent.pressed.connect(func(): _on_button_pressed("Prepare New Content"))
	$VBoxContainer/BottomActionMenu/TextureButtonCats.pressed.connect(func(): _on_button_pressed("Take Care of your Cats"))
	$VBoxContainer/BottomActionMenu/TextureButtonSocialMedia.pressed.connect(func(): _on_button_pressed("Maintain your Social Media"))
	$VBoxContainer/BottomActionMenu/TextureButtonNewVideo.pressed.connect(func(): _on_button_pressed("Post a New Video"))
	$VBoxContainer/BottomActionMenu/TextureButtonGoLive.pressed.connect(func(): _on_button_pressed("Go Live on Twitch"))
	$VBoxContainer/BottomActionMenu/TextureButtonTakeBreak.pressed.connect(func(): _on_button_pressed("Take a Break"))

	slide_panel.position = Vector2(-slide_panel.size.x, 0)
	slide_panel.visible = true
	await get_tree().process_frame

func _process(_delta):
	if GameState.beans >= 100 and GameState.bean_boost_level == 0 and not has_node("BeanDonationBlocker"):
		show_bean_donation_popup()

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
	popup.get_node("VBoxContainer/BeanLabel").text = "You've collected 100 bean cans.\nWould you like to donate them to permanently boost your follower gain rate?\nYou can donate again later by clicking your bean counter."

	var yes_button = popup.get_node("VBoxContainer/HBoxContainer/YesButton")
	var no_button = popup.get_node("VBoxContainer/HBoxContainer/NoButton")
	var warning_label = popup.get_node("VBoxContainer/WarningLabel")
	warning_label.text = ""  

	yes_button.pressed.connect(func():
		if GameState.beans >= 100:
			GameState.beans = max(GameState.beans - 100, 0)
			GameState.bean_boost_level += 1
			GameState.update_sub_rate()
			update_top_stats()
			blocker.queue_free()
		else:
			warning_label.text = "You need at least 100 beans to donate!"
	)

	no_button.pressed.connect(func():
		blocker.queue_free()
	)

	blocker.add_child(popup)
	add_child(blocker)


func _on_LabelBeans_pressed():
	if GameState.beans >= 100:
		show_bean_donation_popup()

func _try_spawn_bean():
	if is_any_popup_open():
		return
	if randf() < 1.0:
		spawn_bean()

func spawn_bean():
	var bean_scene = preload("res://assets/Bean.tscn")
	var bean = bean_scene.instantiate()
	$BeanLayer.add_child(bean)

func start_subscriber_timer():
	if sub_timer and sub_timer.is_inside_tree():
		return
	sub_timer = Timer.new()
	sub_timer.wait_time = randf_range(1.5, 3.0)
	sub_timer.autostart = false
	sub_timer.one_shot = true
	sub_timer.timeout.connect(_on_sub_tick)
	add_child(sub_timer)
	sub_timer.start()

func _on_sub_tick():
	if is_any_popup_open():
		sub_timer.start(randf_range(1.5, 3.0))
		return
	GameState.tick_subscriber_gain()
	update_top_stats()
	sub_timer.start(randf_range(1.5, 3.0))

func _on_button_pressed(action_name: String):
	if GameState.confirmation_mode:
		$ConfirmationPopupLayer/ConfirmationPopup.show_action_confirmation(action_name)
	else:
		finalize_action(action_name)

func finalize_action(action_name: String):
	GameState.choice = action_name
	GameState.record_action(action_name)
	GameState.apply_action_effects(action_name)

	if GameState.week > 1 and GameState.day < 7 and not GameState.has_had_random_event_this_week:
		if randf() < 0.2:
			trigger_random_event(GameState.choice)
			GameState.has_had_random_event_this_week = true

	if GameState.day == 7:
		GameState.process_week_summary(week_summary_popup)
		GameState.day = 1
		GameState.week += 1
		GameState.reset_choice()
		update_day_label()
		save_game()
		return

	GameState.day += 1
	GameState.reset_choice()
	update_day_label()
	show_day_popup()
	save_game()

func update_day_label():
	label_day_info.text = "Day %d, Week %d" % [GameState.day, GameState.week]

func update_top_stats():
	label_beans.text = "Beans: %d" % GameState.beans
	label_twitch.text = "Followers: %d" % GameState.twitch_subs
	label_happiness.text = "Raven Happiness: %d" % GameState.raven_happiness
	label_feedback.text = "Viewer Feedback: %s" % GameState.feedback

func show_day_popup():
	var text = "Day %d, Week %d" % [GameState.day, GameState.week]
	day_label.text = text
	$DayStartPopup.visible = true
	day_label.modulate.a = 0.0
	var tween = get_tree().create_tween()
	tween.tween_property(day_label, "modulate:a", 1.0, 0.5)
	await tween.finished
	await get_tree().create_timer(1.5).timeout
	tween = get_tree().create_tween()
	tween.tween_property(day_label, "modulate:a", 0.0, 0.5)
	await tween.finished
	$DayStartPopup.visible = false

func save_game():
	var save_data := {
		"day": GameState.day,
		"week": GameState.week,
		"twitch_subs": GameState.twitch_subs,
		"raven_happiness": GameState.raven_happiness,
		"feedback": GameState.feedback
	}
	var file := FileAccess.open("user://savegame.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()

func load_game():
	if FileAccess.file_exists("user://savegame.json"):
		var file = FileAccess.open("user://savegame.json", FileAccess.READ)
		var content = file.get_as_text()
		file.close()

		var parsed: Variant = JSON.parse_string(content)

		if parsed:
			GameState.day = parsed.get("day", 1)
			GameState.week = parsed.get("week", 1)
			GameState.twitch_subs = parsed.get("twitch_subs", 0)
			GameState.raven_happiness = parsed.get("raven_happiness", 100)
			GameState.feedback = parsed.get("feedback", "Alright")

func _on_menu_pressed() -> void:
	toggle_menu_panel()

func toggle_menu_panel():
	menu_open = !menu_open
	var target_pos = Vector2(0, 0) if menu_open else Vector2(-slide_panel.size.x, 0)
	var tween = create_tween()
	tween.tween_property(slide_panel, "position", target_pos, 0.25)

	if menu_open:
		slide_panel.get_node("VBoxContainer").visible = true
	else:
		tween.tween_callback(func():
			slide_panel.get_node("VBoxContainer").visible = false)

	slide_panel.mouse_filter = Control.MOUSE_FILTER_STOP if menu_open else Control.MOUSE_FILTER_IGNORE

func trigger_random_event(action: String):
	if not RANDOM_EVENTS.has(action):
		return

	var valid = RANDOM_EVENTS[action].filter(func(e): return e.condition.call())
	if valid.is_empty():
		return

	var selected = valid.pick_random()
	var text = "[b]%s[/b]\n%s\n%s" % [selected.title, selected.description, selected.outcome]
	show_event_popup(text, selected.effect)


func show_event_popup(text: String, callback: Callable):
	var blocker := Control.new()
	blocker.name = "PopupBlocker"
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


	var popup_scene = preload("res://assets/EventPopup.tscn")
	var popup = popup_scene.instantiate()
	popup.get_node("VBoxContainer/EventLabel").text = text

	popup.get_node("VBoxContainer/ContinueButton").pressed.connect(func():
		callback.call()
		blocker.queue_free()
	)

	blocker.add_child(popup)
	add_child(blocker)

func boost_bean_rate_for_seconds(seconds: float):
	if bean_rate_boost_timer:
		bean_rate_boost_timer.queue_free()

	bean_rate_boost_timer = Timer.new()
	bean_rate_boost_timer.wait_time = seconds
	bean_rate_boost_timer.one_shot = true
	bean_rate_boost_timer.timeout.connect(func():
		bean_timer.wait_time = 5.0)
	add_child(bean_rate_boost_timer)
	bean_rate_boost_timer.start()

	bean_timer.wait_time = 0.8 

func _on_button_toggle_confirm_pressed() -> void:
	GameState.confirmation_mode = !GameState.confirmation_mode

func _on_button_toggle_music_pressed() -> void:
	MusicManager.toggle_music()

func _on_button_skip_song_pressed() -> void:
	MusicManager.skip_song()

func _on_button_quit_pressed() -> void:
	get_tree().quit()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if label_beans.get_global_rect().has_point(get_global_mouse_position()):
			if GameState.beans >= 100:
				show_bean_donation_popup()
