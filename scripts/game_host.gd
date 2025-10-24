extends Node

# Scene references
@onready var main_stage = $MainStage
@onready var tanky = $MainStage/Tanky
@onready var ui = $MainStage/UI
@onready var bgm = $BGM

var lives = 3

func _ready():
	# Connect tanky death signal
	tanky.died.connect(_on_tanky_died)
	
	# Start background music
	if bgm:
		bgm.play()

func _on_tanky_died():
	lives -= 1
	ui.update_lives(lives)
	
	if lives >= 1:
		# Respawn after a delay
		await get_tree().create_timer(1.0).timeout
		tanky.respawn()
	else:
		# Game over
		ui.show_game_over()
