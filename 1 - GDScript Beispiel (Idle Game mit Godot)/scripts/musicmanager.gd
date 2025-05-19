extends Node

var music_player: AudioStreamPlayer
var playlist: Array[AudioStream] = []
var current_track_index := 0
var music_enabled := true

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	playlist = [
	preload("res://assets/songutopia.mp3"),
	preload("res://assets/songfever.mp3"),
	preload("res://assets/songiceonmyteeth.mp3"),
	preload("res://assets/songpirateking.mp3"),
	preload("res://assets/songstar1117.mp3"),
	preload("res://assets/songtwilight.mp3"),
	]

	play_next()

	music_player.finished.connect(play_next)

func play_next():
	if not music_enabled or playlist.is_empty():
		return

	current_track_index = (current_track_index + 1) % playlist.size()
	music_player.stream = playlist[current_track_index]
	music_player.play()

func toggle_music():
	music_enabled = !music_enabled
	if music_enabled:
		play_next()
	else:
		music_player.stop()

func skip_song():
	if music_enabled:
		play_next()
