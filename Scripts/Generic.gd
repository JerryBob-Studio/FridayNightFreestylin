extends Node

@onready var Global = get_node("/root/Global")

#---- Scenes
const objBox = preload("res://Scenes/UI/box.tscn")
const objHitMarker = preload("res://Scenes/UI/hitMarker.tscn")
const objHitScore = preload("res://Scenes/UI/hitScoreText.tscn")
const objArrow = preload("res://Scenes/UI/fnfArrow.tscn")

#---- Materials
const matFunky = preload("res://Materials/Funky mat.tres")

#---- Consts
const globalUIHues = [
	0.01, 0.04, 0.14,
	0.27, 0.54, 0.76
]
const fnfHues = [0.01, 0.54, 0.27, 0.76]
const arrowRots = [PI, PI / 2., PI / -2., 0.]
const levelNames = [
	"Bob",
	"Stef",
	"Moe"
]

#---- Data
var levels = [
	newLevel(
		"Bob", [88.], 3,
		[
			"        ",
			"        ",
			"        ",
			"0   1   ",
			"3   4   ",
			"0 2 1   ",
			"3   4 5 ",
			"4   11  ",
			"3   00  ",
			"123 450 ",
			"4 1 1 0 ",
			"0   1   ",
			"3   4   ",
			"0 2 1   ",
			"3   4 5 ",
			"4   11  ",
			"3   00  ",
			"123 450 ",
			"4 1 1 0 ",
			"00    3 ",
			" "
		],
		[1, 2, 0, 1, 2, 0]
	),
	newLevel(
		"Stef", [96.], 0,
		[
			"        ",
			"        ",
			"3 33  1 ",
			"33 3 14 ",
			"3 33  1 ",
			"33 3 14 ",
			"111 53 5",
			"101 35 3",
			"3 33  1 ",
			"33 3 14 ",
			"3 33  1 ",
			"33 3 14 ",
			"111 53 5",
			"101 35 3",
			"3 33  1 ",
			"33 3 14 ",
			"3 33  1 ",
			"33 3 14 ",
			"111 53 5",
			"101 35 3",
			"3 33  1 ",
			"33 3 14 ",
			"3 33  1 ",
			"33 3 14 ",
			"111 53 5",
			"101 35 3",
			"        "
		],
		[1, 1, 2, 2, 3, 3]
	),
	newLevel(
		"Moe",
		[
			153.,
			[160., 14],
			[174., 18],
			[141., 34],
			[152., 55],
			[164., 57],
			[120., 86]
		], 0,
		[
			"1111",
		],
		[1, 2, 0, 1, 2, 0]
	),
	newLevel(
		"Test",
		[
			135.,
			[150., 1],
			[170., 2],
			[115., 3]
		], 0,
		[
			"1414",
			"1414",
			"1414",
			"1414",
			"1414",
			"1414",
			"1414",
			"1414",
		],
		[1, 2, 0, 1, 2, 0]
	),
]

#---- Classes
class levelData:
	var songName = ""
	var bpm = 0
	var offset = 0 #Offset in sections
	var sections = []
	var keyTypes = []

func newLevel(songName, bpm, offset, sections, keyTypes):
	var new = levelData.new()
	new.songName = songName
	new.bpm      = bpm
	new.offset   = offset
	new.sections = sections
	new.keyTypes = keyTypes
	return new
	
class Arrow:
	var hit = false
	var index = 0
	var pos = 0.
	var obj

func newArrow(hit, index, pos, obj):
	var new = Arrow.new()
	new.hit   = hit
	new.index = index
	new.pos   = pos
	new.obj   = obj
	return new

#---- General Funcs
func loadScene(scn, delete):
	get_tree().root.call_deferred("add_child", load("res://Scenes/" + scn + ".tscn").instantiate())
	if delete:
		delete.queue_free()

func getFontIndex(c):
	return c.unicode_at(0) - 32

func charFrame(char, frame):
	char.frame = frame
	char.get_child(1).frame = frame

#---- UI Funcs
func globalUIColour(hue):
	return Color.from_hsv(hue, 2./3., 0.78)

func uiLerpVal(val, ui, speed):
	return ui + (val - ui) * speed

func updateText(obj, txt, x, y, s):
	for i in len(txt):
		var fontIndex = getFontIndex(txt[i])
		obj.set_cell(0, Vector2i(i, 0), 1, Vector2i(fontIndex % 8, fontIndex / 8))
	obj.position.x = x - len(txt) * 128. * s
	obj.position.y = y - 128. * s
	obj.scale = Vector2(s, s)

#---- UI Element Funcs
func createBox(x, y, w, h, col, parent):
	var new = objBox.instantiate()
	new.position = Vector2(x, y)
	new.scale = Vector2(w, h)
	new.self_modulate = col
	
	parent.add_child(new)
	return new

func createHitMarker(x, y, s, col, type, keyIndex, parent):
	var new = objHitMarker.instantiate()
	new.position = Vector2(x, y)
	new.scale = Vector2(s, s)
	
	var sprites = new.get_children()
	sprites[0].self_modulate = col
	sprites[2].self_modulate = col
	for i in 3:
		sprites[i].frame = type
	sprites[3].frame = keyIndex
	
	parent.add_child(new)
	return new

func createHitScore(x, y, s, type, parent):
	var new = objHitScore.instantiate()
	new.position = Vector2(x, y)
	new.rotation = randf() * PI - PI / 2.
	new.apply_force(Vector2(0, randf() * 400. - 4000.).rotated(new.rotation))
	
	var sprite = new.get_child(0)
	sprite.scale = Vector2(s, s)
	sprite.frame = type
	match type:
		0: sprite.self_modulate = globalUIColour(globalUIHues[0])
		1: sprite.self_modulate = globalUIColour(globalUIHues[4])
		2: sprite.material = matFunky
		3: sprite.self_modulate = Color(0.25, 0.25, 0.25)
	
	parent.add_child(new)
	return new

func createArrow(x, y, rot, s, col, parent):
	var new = objArrow.instantiate()
	new.position = Vector2(x, y)
	new.rotation = rot
	new.scale = Vector2(s, s)
	new.self_modulate = col
	
	parent.add_child(new)
	return new
