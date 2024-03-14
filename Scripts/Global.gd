extends "res://Scripts/Generic.gd"

var DEBUG_SKIPTOGAMEPLAY = false

var azerty = false
var keybinds = "AZEQSD" if azerty else "QWEASD"
var fnfKeybinds1 = "QSZD" if azerty else "ASWD"
var fnfKeybinds2 = [KEY_LEFT, KEY_DOWN, KEY_UP, KEY_RIGHT]

var level = 0

func _ready():
	if DEBUG_SKIPTOGAMEPLAY:
		loadScene("gameplayMain", false)
	else:
		loadScene("keyboard", false)
