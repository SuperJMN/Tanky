extends Area2D

# Animation
var current_frame = 0
var total_frames = 24  # 7 columns * 4 rows - 4 empty = 24
var frame_timer: Timer

@onready var sprite = $Sprite2D
@onready var sound = $ExplosionSound

func _ready():
	# Setup collision
	collision_layer = 16  # Explosion layer
	collision_mask = 2    # Enemy layer
	add_to_group("explosion")
	
	# Setup animation timer
	frame_timer = Timer.new()
	frame_timer.wait_time = 0.02
	frame_timer.timeout.connect(_on_frame_timer_timeout)
	add_child(frame_timer)
	frame_timer.start()
	
	# Play sound
	if sound:
		sound.play()

func _on_frame_timer_timeout():
	current_frame += 1
	
	# Update sprite frame
	if sprite:
		var columns = 7
		var frame_x = current_frame % columns
		var frame_y = int(current_frame / columns)
		sprite.frame_coords = Vector2i(frame_x, frame_y)
	
	# Remove when animation finishes
	if current_frame >= total_frames:
		call_deferred("queue_free")
