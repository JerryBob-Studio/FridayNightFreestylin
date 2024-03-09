extends "res://Scripts/Generic.gd"

@export var azerty = false
@export var level = 0

func _ready():
	var kbd = load("res://Scenes/keyboard.tscn").instantiate()
	self.add_child(kbd)
	updateText(kbd.get_child(0), "SELECT KEYBOARD TYPE.", 960., 360., 0.3)
