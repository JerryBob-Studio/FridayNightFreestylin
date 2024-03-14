extends "res://Scripts/Generic.gd"

@export var fnc = ""
@export var txt = ""
@export var siz = 1.

func snd():
	var curScene = get_tree().root.get_child(1) #HACK, but I ain't fixin' it.
	curScene.get_node("Music").stop()
	curScene.get_node("Confirm").play()

func _ready():
	updateText(self.get_child(0), txt, self.size.x / 2., self.size.y / 2., siz)

func _on_pressed():
	var curScene = get_tree().root.get_child(1) #Exact same stinky HACK, still not fixin' it.
	match fnc:
		#Menu
		"Play":
			snd()
			await get_tree().create_timer(4.).timeout
			loadScene("funkin", curScene)
		#Game Over
		"Retry":
			snd()
			await get_tree().create_timer(4.).timeout
			loadScene("gameplayMain", curScene)
		"QWERTY":
			Global.azerty = false
			loadScene("menu", curScene)
		"AZERTY":
			Global.azerty = true
			loadScene("menu", curScene)
		"Exit":
			snd()
			await get_tree().create_timer(4.).timeout
			get_tree().quit()
