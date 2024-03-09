extends "res://Scripts/Generic.gd"

#DEBUG
var DEBUG_HITSCORE = false

#Objects
@onready var hostPlayhead = createBox(360, 54, 5, 72, Color(1, 0, 0), $UI)
@onready var remixerPlayhead = createBox(360, 130, 5, 72, Color(0, 1, 1), $UI)

#Player settings
@onready var keybinds = "AZEQSD" if get_node("/root/Global").azerty else "QWEASD"

#Song
var songName = "Test"
var bpm = 86.
var offset = 0 #Offset in sections
var sections = [
	"3 4   1 ",
	"3333 5 3",
	"012 345 ",
	"3333 5 3",
	" "
]
var keyHues = globalUIHues
var keyTypes = [
	1, 2, 0,
	1, 2, 0
]

#Samples
var sounds = []

#Current beat
var beats = 0
var beatsFloat = 0.
var beatsClosest = 0

#Current section state
var started = false
var sectionNum = 0
var curSection = sections[0]
var hostTurn = true

#Player stats
var score = 0.
var EPICNESS = 0.5

#Remixer
var sectionScore = 0.
var remixerHits = []
var lastRepeat = 0
var lastKey = -1
var lastHitTime = -1
var alterHits = 0
var queuePress = -1

#Host
var hostHits = 0
var hostLastHit = 0

#UI
var timelinePos = 360.

#UI lerp values
var scoreUI = 0.
var epicnessUI = 0.5

#----

func calcHitScore(time):
	var result = 4.
	var amt = 4
	for i in amt:
		result *= pow(abs(sin(time / pow(2, i - 1) * PI)), 2.)
	result *= amt
	result = 1. - result
	return result

func canPlay():
	return sectionNum >= offset and sectionNum < len(sections)

func hit(soundStream, key):
	createHitMarker(timelinePos, 54 if hostTurn else 130, 0.5, globalUIColour(keyHues[key]), keyTypes[key], getFontIndex(keybinds[key]), $UI/HitMarkers)
	soundStream.stream = sounds[key]
	soundStream.play()

#CLEANUP: This shit looks nasty af
func hitRemixer(key):
	var hitScore = calcHitScore(beatsFloat * 2)
	var hitUIType = -1
	
	if key == lastKey or lastKey == -1:
		lastRepeat += 1
	else:
		lastRepeat = 1
		lastKey = -1
	
	#Copying the host
	if curSection[beatsClosest] == str(key) and not remixerHits[beatsClosest]:
		sectionScore += hitScore / 2.5 + 0.5
		remixerHits[beatsClosest] = true
		hitUIType = 1 if hitScore > 0.5 else 0
	
	#Freestyling!
	else:
		var freshness = 0
		if (beatsFloat - lastHitTime) < 0.075 and lastHitTime != -1:
			freshness = -0.69
		else:
			freshness = 1.1 / lastRepeat
		
		hitUIType = 3 if freshness < 0.2 else (2 if hitScore > 0 else 0)
		hitScore *= freshness / (alterHits + 1.)
		sectionScore += hitScore
		
		if curSection[beatsClosest] != " ":
			alterHits += 1
	
	hit($RemixerSounds, key)
	createHitScore(960, 540, 0.5, hitUIType, $UI)
	
	if lastKey == -1:
		lastKey = key
	queuePress = -1
	lastHitTime = beatsFloat

func nextSection():
	if not hostTurn and sectionNum < len(sections) - 1:
		score += sectionScore
		EPICNESS += (sectionScore - hostHits) / 25.
		EPICNESS = max(min(EPICNESS, 1.), 0.)
		sectionScore = 0.
		hostHits = 0
		
		sectionNum += 1
		curSection = sections[sectionNum]
		resetInputs()
	beats = 0
	beatsFloat = 0
	hostTurn = !hostTurn

func resetInputs():
	for i in $UI/HitMarkers.get_children():
		i.queue_free()
	
	remixerHits = []
	for i in len(curSection):
		remixerHits.append(false)
	
	lastRepeat = 0
	lastKey = -1
	lastHitTime = -1
	alterHits = 0
	hostLastHit = -1

func updatePlayheads():
	timelinePos = 360 + beatsFloat / len(curSection) * 1200
	hostPlayhead.position.x = timelinePos + (0 if hostTurn else 1200)
	remixerPlayhead.position.x = timelinePos - 1200 + (0 if hostTurn else 1200)
	if DEBUG_HITSCORE:
		createBox(timelinePos, 90, 8, 150, Color(1. - calcHitScore(beatsFloat * 2), calcHitScore(beatsFloat * 2), 0, 1.), $UI)

func updateEPICNESS():
	$UI/HostEpicnessBox.scale.y = (1. - epicnessUI) * 256.
	$UI/RemixerEpicnessBox.scale.y = epicnessUI * 256.

func updateUI():
	scoreUI = uiLerpVal(score, scoreUI, 0.1)
	epicnessUI = uiLerpVal(EPICNESS, epicnessUI, 0.1)
	updatePlayheads()
	updateEPICNESS()
	updateText($UI/ScoreText, "SCORE " + str(int(ceil(scoreUI * 10.))), 960, 1080 - 96, 0.1667)

#----

func _ready():
	$Music.stream = load("res://Levels/" + songName + "/" + songName + " song.ogg")
	
	#Load samples
	for key in len(keybinds):
		sounds.append(load("res://Levels/" + songName + "/" + songName + " chop " + str(key) + ".wav"))
	
	#Timeline lines
	var totalLines = 32
	for i in totalLines:
		var pos = 360 + i * 1200. / totalLines
		if   i % 8 == 0: createBox(pos, 90, 8, 150, Color(0, 0, 0), $UI)
		elif i % 8 == 4: createBox(pos, 90, 5, 150, Color(0, 0, 0, 0.75), $UI)
		elif i % 8 == 2 or i % 8 == 6: createBox(pos, 90, 3, 150, Color(0, 0, 0, 0.5), $UI)
		else: createBox(pos, 90, 2, 150, Color(0, 0, 0, 0.25), $UI)
	
	resetInputs()

#----

func _process(delta):
	#Start
	if !started:
		$Music.play()
		$BeatTimer.wait_time = 60. / bpm
		$BeatTimer.start()
		_on_beat_timer_timeout()
		started = true
	
	#Beats & time
	beatsFloat += bpm / 60. * delta
	beats = floor(beatsFloat)
	beatsClosest = int(min(round(beatsFloat), len(curSection) - 1))
	if beats >= len(sections[sectionNum]):
		nextSection()
	
	#Rotate record at 45 RPM
	$"Record Player/Record".rotation.y = -$Music.get_playback_position() * PI * 45. / 60.
	
	if canPlay():
		updateUI()
		
		#Host play
		if hostTurn and hostLastHit != beats and curSection[beats] != " ":
			hit($HostSounds, int(curSection[beats]))
			hostHits += 1
			hostLastHit = beats
		
		#Remixer queued press
		if canPlay() and not hostTurn and queuePress != -1:
			hitRemixer(queuePress)
	
	if not $Music.playing and EPICNESS > 0.5:
		nextLevel()
	else:
		gameover()

#----

func _input(e):
	#Remixer hit
	for key in len(keybinds):
		if e is InputEventKey and Input.is_key_pressed(OS.find_keycode_from_string(keybinds[key])) and e.is_pressed() and not e.echo:
			if canPlay() and not hostTurn:
				hitRemixer(key)
			elif beatsFloat > len(curSection) - 0.5:
				queuePress = key

func _on_beat_timer_timeout():
	pass
