extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
var timer: Timer
var fps := 30.0
var start_frame := 2

func _ready():
	# Setup collision
	collision_layer = 16  # Explosion layer
	collision_mask = 2    # Enemy layer
	add_to_group("explosion")
	
	# Setup animation timer to iterate through sprite sheet frames
	sprite.frame = start_frame
	timer = Timer.new()
	timer.wait_time = 1.0 / fps
	timer.one_shot = false
	timer.timeout.connect(_on_tick)
	add_child(timer)
	timer.start()

func _on_tick():
	var total := sprite.hframes * sprite.vframes
	if sprite.frame >= total - 1:
		call_deferred("queue_free")
		return
	sprite.frame += 1
