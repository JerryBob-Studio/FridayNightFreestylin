extends "res://Scripts/Generic.gd"

@export var fnc = ""
@export var txt = ""
@export var siz = 1.

func loadMenu():
	get_tree().root.add_child(load("res://Scenes/menu.tscn").instantiate())
	get_node("/root/Global/Keyboard").queue_free()

func snd():
	$"../Music".stop()
	$"../MenuSfx".play()

func _ready():
	updateText(self.get_child(0), txt, self.size.x / 2., self.size.y / 2., siz)

func _on_pressed():
	match fnc:
		#Menu
		"Play":
			snd()
			await get_tree().create_timer(2.8).timeout
			get_node("/root/Global").add_child(load("res://Scenes/gameplayMain.tscn").instantiate())
			get_node("/root/Menu").queue_free()
		
		#Game Over
		"Retry":
			get_tree().reload_current_scene()
		
		#Keyboard
		"QWERTY":
			Global.azerty = false
			loadMenu()
		"AZERTY":
			Global.azerty = true
			loadMenu()
		
		#Generic
		"Exit":
			snd()
			await get_tree().create_timer(2.8).timeout
			get_tree().quit()
