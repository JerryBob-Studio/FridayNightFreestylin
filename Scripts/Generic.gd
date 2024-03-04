extends Node2D

var objBox = preload("res://Scenes/box.tscn")
var objHitMarker = preload("res://Scenes/hitMarker.tscn")
var objHitScore = preload("res://Scenes/hitScoreText.tscn")

var matFunky = preload("res://Materials & Shaders/Funky mat.tres")

func createBox(x, y, w, h, col, parent):
	var new = objBox.instantiate()
	new.position = Vector2(x, y)
	new.scale = Vector2(w, h)
	new.self_modulate = col
	parent.add_child(new)
	return new

func createHitMarker(x, y, s, col, type, keyIndex, parent):
	var new = objHitMarker.instantiate()
	var sprites = new.get_children()
	new.position = Vector2(x, y)
	new.scale = Vector2(s, s)
	sprites[0].self_modulate = col
	sprites[2].self_modulate = col
	for i in 3:
		sprites[i].frame = type
	sprites[3].frame = keyIndex
	parent.add_child(new)
	return new

func createHitScore(x, y, s, type, parent):
	var new = objHitScore.instantiate()
	var sprite = new.get_child(0)
	new.position = Vector2(x, y)
	new.scale = Vector2(s, s)
	new.rotation = randf() * PI - PI / 2.
	new.apply_force(Vector2(0, randf() * 400. - 4000.).rotated(new.rotation))
	sprite.frame = type
	sprite.material = matFunky if type == 2 else null
	parent.add_child(new)
	return new
