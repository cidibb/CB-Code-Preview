extends Node

var day := 1
var week := 1
var beans := 0
var twitch_subs := 0
var last_week_subs := 0
var raven_happiness := 100

var feedback_score := 50
var feedback := "Alright"

var charisma := 0.0
var content_quality := 0.0
var cat_health := 100.0
var online_presence := 0.0
var did_care_for_cats_today := false
var has_had_random_event_this_week := false
var weeks_without_random_event := 0

var choice := ""
var confirmation_mode := false
var week_actions := []
var sub_gain_rate := 0.0
var sub_progress := 0.0
var bean_boost_level := 0

func reset_choice():
	choice = ""

func record_action(action: String):
	week_actions.append(action)

func decay_hidden_stats():
	charisma = max(charisma - 1.0, 0)
	content_quality = max(content_quality - 1.0, 0)
	online_presence = max(online_presence - 1.0, 0)

func process_week_summary(popup):
	var cat_days := week_actions.count("Take Care of your Cats")
	var charisma_days := week_actions.count("Work on your Charisma")
	var video_days := week_actions.count("Post a New Video") + week_actions.count("Go Live on Twitch")
	var break_days := week_actions.count("Take a Break")

	var old_happiness = raven_happiness
	var old_subs = twitch_subs
	
	if has_had_random_event_this_week:
		weeks_without_random_event = 0
	else:
		weeks_without_random_event += 1

	has_had_random_event_this_week = false

	charisma = max(charisma - 1.5, 0)
	content_quality = max(content_quality - 1.5, 0)
	online_presence = max(online_presence - 1.5, 0)

	charisma += charisma_days * 5.0
	content_quality += video_days * 5.0

	var cat_warning := ""
	if cat_days >= 1:
		cat_health += 40
	else:
		cat_health -= 25
		cat_warning = "You ignored the cats all week! They're feeling neglected... >:("
		if cat_health <= 0:
			game_over()
	cat_health = clamp(cat_health, 0, 100)

	match break_days:
		2:
			raven_happiness += 5
		1:
			raven_happiness -= 10
		0:
			raven_happiness -= 25
	raven_happiness = clamp(raven_happiness, 0, 100)

	var avg_content = (charisma + content_quality) / 2.0
	if avg_content >= 70:
		feedback_score += 10
	elif avg_content >= 50:
		feedback_score += 5
	elif avg_content >= 35:
		feedback_score += 0
	elif avg_content >= 20:
		feedback_score -= 5
	else:
		feedback_score -= 10

	if break_days == 2 and cat_days >= 1:
		feedback_score += 10

	feedback_score = clamp(feedback_score, 0, 100)
	feedback = get_feedback_text(feedback_score)

	update_sub_rate()
	twitch_subs += int(sub_gain_rate * 7)
	twitch_subs = max(twitch_subs, 0)

	var sub_change = twitch_subs - old_subs
	var happiness_change = raven_happiness - old_happiness
	var feedback_msg = random_feedback_message(feedback)
	popup.show_summary(sub_change, happiness_change, feedback, cat_warning, feedback_msg)

	last_week_subs = twitch_subs
	week_actions.clear()
	did_care_for_cats_today = false

func get_feedback_text(score: int) -> String:
	if score >= 90:
		return "OMG 10/10 POGGERS!!!111"
	elif score >= 75:
		return "Slay queen"
	elif score >= 60:
		return "Alright"
	elif score >= 45:
		return "Meh I guess"
	elif score >= 30:
		return "Kinda bad"
	else:
		return "You kinda suck bro"

func update_sub_rate():
	var avg_content = (charisma + content_quality + online_presence) / 3.0
	sub_gain_rate = avg_content * 0.05
	sub_gain_rate *= 1.0 + (bean_boost_level * 0.05)

	match feedback:
		"OMG 10/10 POGGERS!!!111": sub_gain_rate *= 2.5
		"Slay queen": sub_gain_rate *= 2.0
		"Alright": sub_gain_rate *= 1.5
		"Meh I guess": sub_gain_rate *= 1.0
		"Kinda bad": sub_gain_rate *= 0.5
		"You kinda suck bro": sub_gain_rate = -2

	sub_gain_rate = clamp(sub_gain_rate, -10, 20)

func tick_subscriber_gain():
	sub_progress += sub_gain_rate
	if sub_progress >= 1.0:
		var gained = int(sub_progress)
		twitch_subs += gained
		sub_progress -= gained
	twitch_subs = max(twitch_subs, 0)

func apply_action_effects(action_name: String):
	match action_name:
		"Work on Charisma":
			charisma += 5.0
		"Prepare Content":
			content_quality += 5.0
		"Take Care of Cats":
			did_care_for_cats_today = true
		"Maintain Social Media", "Post a New Video", "Go Live on Twitch":
			online_presence += 5.0
		"Take a Break":
			pass

func game_over():
	get_tree().change_scene_to_file("res://assets/GameOver.tscn")

func random_feedback_message(feedback_type: String) -> String:
	var messages = {
		"OMG 10/10 POGGERS!!!111": [
			"Chobz: omg just marry me already",
			"dolfy_666: this is PEAK content",
			"Hyperion_Knitting: I’m literally screaming irl rn",
			"reaperoffurries: how are you not famous yet??",
			"supertyerestrial: this stream cured my depression",
			"SnaccDealer: I would die for Raven",
			"temujjd: HOW is this FREE??",
			"Locy: BARK BARK BARK BARK BARK",
			"tharezzue: I’ve watched this stream for 3 hours and I’m thriving",
			"DrowKnightmare: tbh this deserves an emmy"
		],

		"Slay queen": [
			"Sh4dyLady: yas queen step on me",
			"ToeBeansSupreme: legit eating up the screen rn",
			"BongLord87: this stream has no business slaying this hard",
			"meowmix6969: i would simp for this energy",
			"HotPocketDad: i’m here for the drama AND the slay",
			"CursedMuffin: honestly? serving.",
			"RatQueen: pls never log off ever again",
			"GremlinTV: not me clapping alone in my room",
			"DramaLlama69: this is why I canceled my therapy appointment",
			"SugarRatz: stream got me kicking my feet fr"
		],

		"Alright": [
			"SippyCupWarrior: not bad, not bad",
			"LoFiLemon: we chillin today",
			"JustHere4Vibes: solid 6.5/10 stream tbh",
			"GreaseWeasel: you’ve done better but we stay loyal",
			"RamenSlurper: mood is mellow, not mad about it",
			"yung_gravy_train: not peak but still snackable",
			"ShrimpShawty: i’ve got chips and low expectations, carry on",
			"GoblinSniffer: vibes are neutral and so am i",
			"WidePeepoHappy: it’s fine but i miss the chaos",
			"CrustyToes: this the type of stream you fold laundry to"
		],

		"Meh I guess": [
			"GoblinSniffer: i've seen livestreams of grass growing that were more entertaining",
			"RatKing: this ain’t it chief",
			"FartFiend77: is this supposed to be content?",
			"ZoomerZaddy: bruh... go outside",
			"HotDogJuggler: stream running on fumes today huh",
			"Ch0k3MeCaptain: mid. absolutely mid.",
			"BoinkHammer: I came for chaos and got chores instead",
			"drizzle420: the stream equivalent of plain toast",
			"ToiletPaperFan: is your editor on strike or sumthin",
			"SkrrtSkrrt99: respectfully... yawn"
		],

		"Kinda bad": [
			"B1tchLasagna: i’m only here out of habit",
			"MeatballMommy: blink twice if you’re okay",
			"FlopGoblin: this stream gave me digital asthma",
			"NPC69420: feels like background noise in purgatory",
			"DannyDeVetoed: if disappointment had a face, it’d be this stream",
			"SoggySocks: even my cat walked away",
			"HooplaDetective: did your content creator license expire?",
			"BrokenTaco: ngl i’m hate-watching at this point",
			"ZzzDonut: this cured my insomnia",
			"YeastMode: you’re losing viewers and gaining enemies"
		],

		"You kinda suck bro": [
			"ToeSnail99: this feels like a cry for help",
			"C4mpfireCringe: uninstall the internet",
			"SweatyGoblin: this stream lowered my IQ",
			"ILikePain: i’m watching just to feel something",
			"TrashBoat666: bring back the loading screen tbh",
			"b00bSlapper: this stream made my wi-fi faster when i closed it",
			"ClownFiesta: i’m embarrassed for you and i don’t even know you",
			"SadBoiSlim: just stream your tears it’d be more engaging",
			"SockGremlin: someone pls pull the ethernet cable",
			"FlatulentGhost: 2007 britney spears is that you?"
		]
	}
	return messages[feedback_type].pick_random()
