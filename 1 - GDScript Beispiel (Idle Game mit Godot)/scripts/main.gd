extends Control

@onready var new_game_popup = $NewGamePopupLayer/NewGamePopup
@onready var continue_button = $VBoxContainer/ButtonContinue

@onready var toggle_music = $HBoxContainer2/ToggleMusicButton
@onready var skip_button = $SkipSongButton

func _ready():
	toggle_music.button_pressed = MusicManager.music_enabled
	toggle_music.toggle_mode = true
	toggle_music.pressed.connect(_on_toggle_music_pressed)
	skip_button.pressed.connect(_on_skip_song_pressed)
	

	continue_button.visible = FileAccess.file_exists("user://savegame.json")
	$NewGamePopupLayer.visible = false

func _on_button_continue_pressed():
	load_game()
	get_tree().change_scene_to_file("res://assets/Game.tscn")

func _on_button_new_game_pressed():
	if FileAccess.file_exists("user://savegame.json"):
		$NewGamePopupLayer.visible = true
	else:
		_on_confirm_button_pressed() 

func _on_button_quit_pressed():
	get_tree().quit()

func _on_confirm_button_pressed():
	reset_game_state()
	save_game()  
	get_tree().change_scene_to_file("res://assets/Game.tscn")

func _on_cancel_button_pressed():
	$NewGamePopupLayer.visible = false

func reset_game_state():
	GameState.day = 1
	GameState.week = 1
	GameState.twitch_subs = 0
	GameState.raven_happiness = 100
	GameState.feedback = "Alright"
	GameState.beans = 0
	GameState.feedback_score = 50
	GameState.charisma = 0.0
	GameState.content_quality = 0.0
	GameState.cat_health = 100.0
	GameState.online_presence = 0.0
	GameState.did_care_for_cats_today = false
	GameState.choice = ""
	GameState.confirmation_mode = false
	GameState.week_actions.clear()
	GameState.sub_gain_rate = 0.0
	GameState.sub_progress = 0.0
	GameState.has_had_random_event_this_week = false
	GameState.weeks_without_random_event = 0

func _on_toggle_music_pressed():
	MusicManager.toggle_music()
	toggle_music.button_pressed = MusicManager.music_enabled

func _on_skip_song_pressed():
	MusicManager.skip_song()

func save_game():
	var save = {
		"day": GameState.day,
		"week": GameState.week,
		"subs": GameState.twitch_subs,
		"happiness": GameState.raven_happiness,
		"feedback": GameState.feedback,
	}
	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save))
	file.close()

func load_game():
	if not FileAccess.file_exists("user://savegame.json"):
		return

	var file = FileAccess.open("user://savegame.json", FileAccess.READ)
	var save = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(save) == TYPE_DICTIONARY:
		GameState.day = save.get("day", 1)
		GameState.week = save.get("week", 1)
		GameState.twitch_subs = save.get("subs", 0)
		GameState.raven_happiness = save.get("happiness", 100)
		GameState.feedback = save.get("feedback", "Alright")
