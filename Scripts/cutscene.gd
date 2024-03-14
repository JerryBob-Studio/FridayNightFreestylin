extends "res://Scripts/Generic.gd"

func _on_audio_finished():
	loadScene("gameplayMain", self)
