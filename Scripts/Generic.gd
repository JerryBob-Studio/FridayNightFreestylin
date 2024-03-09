extends Node

#Consts
const globalUIHues = [
	0.01, 0.04, 0.14,
	0.27, 0.54, 0.76
]

@onready var Global = get_node("/root/Global")

#Scenes
const objBox = preload("res://Scenes/UI/box.tscn")
const objHitMarker = preload("res://Scenes/UI/hitMarker.tscn")
const objHitScore = preload("res://Scenes/UI/hitScoreText.tscn")

#Materials
const matFunky = preload("res://Materials/Funky mat.tres")

#---- General Funcs

#TODO
func gameover():
	pass

func getFontIndex(c):
	return c.unicode_at(0) - 32

func nextLevel():
	Global.level += 1
	get_tree().root.add_child(load("res://Scenes/gameplayMain.tscn").instantiate())
	self.queue_free()

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
