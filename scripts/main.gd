extends Node2D

@onready var music: AudioStreamPlayer = $Music

func _ready() -> void:
	if music.stream and not music.playing:
		music.play()
