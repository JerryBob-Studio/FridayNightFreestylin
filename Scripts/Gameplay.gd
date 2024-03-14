extends "res://Scripts/Generic.gd"

#DEBUG
var DEBUG_SKIPTO = 0
var DEBUG_HITSCORE = false
var DEBUG_NEXTSONG = false
var DEBUG_FAIL = false
var DEBUG_HEJUSTHASAGOODGAMINGCHAIR = false

#Objects
@onready var hostPlayhead = createBox(360, 54, 5, 72, Color(1, 0, 0), $UI)
@onready var remixerPlayhead = createBox(360, 130, 5, 72, Color(0, 1, 1), $UI)

#Song
var level
var songName
var bpm
var offset
var sections
var keyTypes
var keyHues = globalUIHues
var sounds = []

#General status
var started = false
var gameOver = false

#Time
var time = 0.
var beatsFloat = 0.
var beats = 0
var beatsClosest = 0
var bpmNext = 1
var curSectionStart = 0.

#Current section state
var sectionNum = DEBUG_SKIPTO
var curSection
var hostTurn = true

#Remixer stats
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
var remixerLastHitTime = 0.

#Host
var hostHits = 0
var hostLastHit = 0
var hostLastHitTime = 0.

#UI
var timelinePos = 360.
var camTarget = 0.

#UI lerp values
var scoreUI = 0.
var epicnessUI = 0.5

#----

func calcHitScore(TIME):
	var result = 4.
	var amt = 4
	for i in amt:
		result *= pow(abs(sin(TIME / pow(2, i - 1) * PI)), 2.)
	result *= amt
	result = 1. - result
	return result

func canPlay():
	return sectionNum >= offset and sectionNum < len(sections)

func hit(soundStream, key):
	createHitMarker(timelinePos, 54 if hostTurn else 130, 0.5, globalUIColour(keyHues[key]), keyTypes[key], getFontIndex(Global.keybinds[key]), $UI/HitMarkers)
	soundStream.stream = sounds[key]
	soundStream.play()

#CLEANUP
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
			freshness = 1.125 / lastRepeat
		
		hitUIType = 3 if freshness < 0.2 else (2 if hitScore > 0 else 0)
		hitScore *= freshness / (alterHits + 1.)
		sectionScore += hitScore
		
		if curSection[beatsClosest] != " ":
			alterHits += 1
	
	hit($RemixerSounds, key)
	createHitScore(960, 540, 0.5, hitUIType, $UI)
	charFrame($Remixer, key / 3 + 1)
	
	remixerLastHitTime = time
	if lastKey == -1:
		lastKey = key
	queuePress = -1
	lastHitTime = beatsFloat
	return hitScore

func nextSection():
	curSectionStart = round($Music.get_playback_position() * bpm / 60.)
	if not hostTurn and sectionNum < len(sections) - 1:
		score += sectionScore
		EPICNESS += (sectionScore - hostHits) / 25.
		EPICNESS = max(min(EPICNESS, 1.), 0.)
		sectionScore = 0.
		hostHits = 0
		
		sectionNum += 1
		curSection = sections[sectionNum]
		resetInputs()
	#BPM changes
	if bpmNext < len(level.bpm) and sectionNum == level.bpm[bpmNext][1]:
		bpm = level.bpm[bpmNext][0]
		bpmNext += 1
	beatsFloat = 0.
	beats = 0
	hostTurn = !hostTurn
	camTarget = 0.75 if hostTurn else -0.75

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
	timelinePos = 360. + beatsFloat / len(curSection) * 1200.
	hostPlayhead.position.x = timelinePos + (0. if hostTurn else 1200.)
	remixerPlayhead.position.x = timelinePos - 1200. + (0. if hostTurn else 1200.)
	if DEBUG_HITSCORE:
		createBox(timelinePos, 90., 8., 150., Color(1. - calcHitScore(beatsFloat * 2), calcHitScore(beatsFloat * 2), 0, 1.), $UI)

func updateEPICNESS():
	$UI/HostEpicnessBox.scale.y = (1. - epicnessUI) * 400.
	$UI/RemixerEpicnessBox.scale.y = epicnessUI * 400.

func updateUI():
	scoreUI = uiLerpVal(score, scoreUI, 0.1)
	epicnessUI = uiLerpVal(EPICNESS, epicnessUI, 0.1)
	updatePlayheads()
	updateEPICNESS()
	updateText($UI/ScoreText, "SCORE " + str(int(ceil(scoreUI * 10.))), 960, 1080 - 96, 0.1667)

#----

func _ready():
	#Get level data
	level = Global.levels[Global.level]
	songName = level.songName
	bpm      = level.bpm[0]
	offset   = level.offset
	sections = level.sections
	keyTypes = level.keyTypes
	curSection = sections[0]
	
	$Music.stream = load("res://Levels/" + songName + "/" + songName + " song.ogg")
	#Debugging
	if DEBUG_NEXTSONG or DEBUG_FAIL:
		EPICNESS = 0. if DEBUG_FAIL else 0.6942069
		$Music.stream = load("res://Audio/Sfx/Confirm.wav")
	
	#Load voiceline
	$Sfx.stream = load("res://Levels/" + songName + "/" + songName + " voiceline.ogg")
	
	#Load samples
	for key in len(Global.keybinds):
		sounds.append(load("res://Levels/" + songName + "/" + songName + " chop " + str(key) + ".wav"))
		#sounds.append(load("res://Levels/Bob/Bob chop " + str(key) + ".wav"))
	
	if Global.level == 1:
		$HostSounds.volume_db = -7.5
		$RemixerSounds.volume_db = -7.5
	
	#Set char textures
	$Host.texture = load("res://Levels/" + songName + "/" + songName + " body.png")
	$Host/HostFace.texture = load("res://Levels/" + songName + "/" + songName + " face.png")
	$Host/HostShadow.texture = $Host.texture
	
	#Timeline lines
	var totalLines = 32
	for i in totalLines:
		var pos = 360 + i * 1200. / totalLines
		if   i % 8 == 0: createBox(pos, 90, 8, 150, Color(0, 0, 0), $UI)
		elif i % 8 == 4: createBox(pos, 90, 5, 150, Color(0, 0, 0, 0.75), $UI)
		elif i % 8 == 2 or i % 8 == 6: createBox(pos, 90, 3, 150, Color(0, 0, 0, 0.5), $UI)
		else: createBox(pos, 90, 2, 150, Color(0, 0, 0, 0.25), $UI)
	
	camTarget = 0.5
	
	resetInputs()

#----

func _process(delta):
	#Stop excecution on game over
	if gameOver:
		return
	
	if DEBUG_HEJUSTHASAGOODGAMINGCHAIR:
		EPICNESS = 69420.
	
	#Start / End
	if not $Music.playing:
		#Start
		if not started:
			if DEBUG_SKIPTO <= 0:
				$Sfx.play()
			$Music.play()
			$Music.seek(DEBUG_SKIPTO * 60. / bpm)
			$BeatTimer.wait_time = 60. / bpm
			$BeatTimer.start()
			_on_beat_timer_timeout()
			started = true
			return
		
		#Level end handler
		else:
			#You did it yaaaaaaaaaaaay
			if EPICNESS >= 0.5:
				if Global.level == 1:
					loadScene("ending", self)
				else:
					Global.level += 1
					loadScene("gameplayMain", self)
			#Game Over
			else:
				self.add_child(load("res://Scenes/UI/gameOver.tscn").instantiate())
				updateText($GameOver/YouSuckAssBro, "GAME OVER", 0., -180., 0.667)
				$Sfx.stream = load("res://Audio/Sfx/Confirm.wav")
				$Music.stream = load("res://Audio/Music/main.ogg")
				$Music.play()
				gameOver = true
	
	#Beats & time
	time = $Music.get_playback_position()
	beatsFloat = time * bpm / 60. - curSectionStart
	beats = floor(beatsFloat)
	beatsClosest = int(min(round(beatsFloat), len(curSection) - 1))
	if beats >= len(sections[sectionNum]):
		nextSection()
	
	var canPlay = canPlay()
	
	#Camera movement
	$Camera3D.position.x = uiLerpVal(camTarget, $Camera3D.position.x, 0.0133)
	
	#Rotate record at 45 RPM
	$"Record Player/Record".rotation.y = -$Music.get_playback_position() * PI * 45. / 60.
	
	#Reset anims
	if time - remixerLastHitTime > 0.15:
		charFrame($Remixer, 3 if not hostTurn else 0)
		if time - remixerLastHitTime > 0.5:
			$Remixer/RemixerFace.frame = 0
	if time - hostLastHitTime > 0.15:
		charFrame($Host, 3 if hostTurn else 0)
		if time - hostLastHitTime > 0.5:
			$Host/HostFace.frame = 0
	
	if canPlay:
		updateUI()
		
		#Host play
		if hostTurn and hostLastHit != beats and curSection[beats] != " ":
			var key = curSection[beats]
			hit($HostSounds, int(key))
			charFrame($Host, int(key) / 3 + 1)
			#$Host/HostFace.frame = [0, 0, 2][randi_range(0, 2)]
			hostHits += 1
			hostLastHit = beats
			hostLastHitTime = time
		
		#Remixer queued press
		if canPlay and not hostTurn and queuePress != -1:
			hitRemixer(queuePress)

#----

func _input(e):
	#Remixer hit
	for key in len(Global.keybinds):
		if e is InputEventKey and Input.is_key_pressed(OS.find_keycode_from_string(Global.keybinds[key])) and e.is_pressed() and not e.echo:
			if canPlay() and not hostTurn:
				var hitScore = hitRemixer(key)
				$Remixer/RemixerFace.frame = (1 if hitScore > 1.093 else (0 if hitScore > 0. else 2)) * 4 + [0, 0, 2][randi_range(0, 2)]
			elif beatsFloat > len(curSection) - 0.5:
				queuePress = key

func _on_beat_timer_timeout():
	pass
