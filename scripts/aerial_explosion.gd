extends Area2D

# Simple aerial explosion - could use AnimatedSprite2D or particles
var lifetime = 0.5
var lifetime_timer: Timer

@onready var sprite = $Sprite2D

func _ready():
	# Setup collision
	collision_layer = 16  # Explosion layer
	collision_mask = 2    # Enemy layer
	add_to_group("explosion")
	
	# Setup lifetime timer
	lifetime_timer = Timer.new()
	lifetime_timer.one_shot = true
	lifetime_timer.wait_time = lifetime
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	add_child(lifetime_timer)
	lifetime_timer.start()
	
	# Fade out animation
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, lifetime)

func _on_lifetime_timeout():
	call_deferred("queue_free")
