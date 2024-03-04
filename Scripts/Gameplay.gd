extends Node2D

#BUGS
#Queued press counts as freestyle press;
#queue is probably a bad idea anyway

#DEBUG
var DEBUG_HITSCORE = false

#Objects
var Generic = preload("res://Scripts/Generic.gd").new()
var hostPlayhead = Generic.createBox(360, 54, 5, 72, Color(1, 0, 0), self)
var remixerPlayhead = Generic.createBox(360, 130, 5, 72, Color(0, 1, 1), self)

#Player settings
var keybinds = "QWEASDRTYFGH"
var numKeys = 6
var keyCols = [
	0.01, 0.04, 0.14,
	0.27, 0.54, 0.76
]
var keyTypes = [
	1, 2, 0,
	1, 2, 0
]

#Song
var songName = "Test"
var bpm = 86.
var offset = 0
var sections = [
	"3 4   1 ",
	"3333 5 3",
	"012 345 ",
	"3333 5 3",
	" "
]

#Samples
var sounds = []
var soundSet = 0

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
	if result < 0.3:
		result *= 1.25
	return result

func canPlay():
	return sectionNum >= offset and sectionNum < len(sections)

func hit(soundStream, key):
	Generic.createHitMarker(timelinePos, 54 if hostTurn else 130, 0.5, keyCols[key], keyTypes[key], getFontIndex(keybinds[key]), $HitMarkers)
	soundStream.stream = sounds[key]
	soundStream.play()

func hitRemixer(key):
	hit($RemixerSounds, key)
	
	var hitScore = calcHitScore(beatsFloat * 2)
	
	if key == lastKey or lastKey == -1:
		lastRepeat += 1
	else:
		lastRepeat = 1
		lastKey = -1
	
	if curSection[beatsClosest] == str(key) and not remixerHits[beatsClosest]:
		sectionScore += hitScore / 10. + 0.9
		remixerHits[beatsClosest] = true
		Generic.createHitScore(960, 540, 1., 1 if hitScore > 0 else 0, self)
	else:
		#Freshness
		var freshness = 0
		if (beatsFloat - lastHitTime) < 0.02 and lastHitTime != -1:
			freshness = -4.2069
		elif key != lastKey or lastKey == -1:
			freshness = 1.25
		else:
			freshness = 1. / lastRepeat
		
		Generic.createHitScore(960, 540, 1., 3 if freshness < 0.2 else (2 if hitScore > 0 else 0), self)
		
		hitScore *= freshness / (alterHits + 1.)
		sectionScore += hitScore
		
		if curSection[beatsClosest] != " ":
			alterHits += 1
	
	if lastKey == -1:
		lastKey = key
	queuePress = -1
	lastHitTime = beatsFloat

func getFontIndex(c):
	return c.unicode_at(0) - 32

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
	for i in $HitMarkers.get_children():
		i.queue_free()
	
	remixerHits = []
	for i in len(curSection):
		remixerHits.append(false)
	
	lastRepeat = 0
	lastKey = -1
	lastHitTime = -1
	alterHits = 0
	hostLastHit = -1

func uiLerpVal(val, txt, speed):
	return (val - txt) * speed

func updatePlayheads():
	timelinePos = 360 + beatsFloat / len(curSection) * 1200
	hostPlayhead.position.x = timelinePos + (0 if hostTurn else 1200)
	remixerPlayhead.position.x = timelinePos - 1200 + (0 if hostTurn else 1200)
	if DEBUG_HITSCORE:
		Generic.createBox(timelinePos, 90, 8, 150, Color(1. - calcHitScore(beatsFloat * 2), calcHitScore(beatsFloat * 2), 0, 1.), self)

func updateEPICNESS():
	$HostEpicnessBox.scale.y = (1. - epicnessUI) * 256.
	$RemixerEpicnessBox.scale.y = epicnessUI * 256.

func updateText(obj, txt, x, y, s):
	for i in len(txt):
		var fontIndex = getFontIndex(txt[i])
		obj.set_cell(0, Vector2i(i, 0), 1, Vector2i(fontIndex % 8, fontIndex / 8))
	obj.position.x = x - len(txt) * 256. * s / 2.
	obj.position.y = y
	obj.scale = Vector2(s, s)

func updateUI():
	scoreUI += uiLerpVal(score, scoreUI, 0.1)
	epicnessUI += uiLerpVal(EPICNESS, epicnessUI, 0.1)
	updatePlayheads()
	updateEPICNESS()
	updateText($ScoreText, "SCORE " + str(int(scoreUI * 10.)), 960, 1080 - 96, 0.1333)

#----

func _ready():
	$Music.stream = load("res://" + songName + "/" + songName + " song.ogg")
	
	#Load key samples and key colours
	for key in numKeys:
		sounds.append(load("res://" + songName + "/set " + str(soundSet) + "/" + songName + " chop " + str(key) + ".wav"))
		keyCols[key] = Color.from_hsv(keyCols[key], 0.65, 0.82)
	
	#Timeline lines
	var totalLines = 32
	for i in totalLines:
		var pos = 360 + i * 1200. / totalLines
		if   i % 8 == 0: Generic.createBox(pos, 90, 8, 150, Color(0, 0, 0), self)
		elif i % 8 == 4: Generic.createBox(pos, 90, 5, 150, Color(0, 0, 0, 0.75), self)
		elif i % 8 == 2 or i % 8 == 6: Generic.createBox(pos, 90, 3, 150, Color(0, 0, 0, 0.5), self)
		else: Generic.createBox(pos, 90, 2, 150, Color(0, 0, 0, 0.25), self)
	
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

#----

func _input(e):
	#Remixer hit
	for key in numKeys:
		if e is InputEventKey and Input.is_key_pressed(OS.find_keycode_from_string(keybinds[key])) and e.is_pressed() and not e.echo:
			if canPlay() and not hostTurn:
				hitRemixer(key)
			elif beatsFloat > len(curSection) - 0.5:
				queuePress = key

func _on_beat_timer_timeout():
	pass
