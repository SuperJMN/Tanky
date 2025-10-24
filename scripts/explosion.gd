extends Area2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var sound = $ExplosionSound

func _ready():
	# Setup collision
	collision_layer = 16  # Explosion layer
	collision_mask = 2    # Enemy layer
	add_to_group("explosion")
	
	# Play animation and sound
	animated_sprite.play("explode")
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	if sound:
		sound.play()

func _on_animation_finished():
	call_deferred("queue_free")
