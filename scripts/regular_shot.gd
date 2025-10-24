extends Area2D

# Shot properties
var shooter: Node2D
var damage = 10
var health_points = 10
var speed = 400.0

@onready var sprite = $Sprite2D

func _ready():
	# Setup collision
	collision_layer = 4  # PlayerShot layer
	collision_mask = 2   # Enemy layer
	add_to_group("player_shot")
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Move right
	position.x += speed * delta
	
	# Remove if out of bounds
	if position.x > get_viewport_rect().size.x + 50:
		call_deferred("queue_free")

func _on_area_entered(area):
	if area.is_in_group("enemy"):
		receive_damage(area.damage if "damage" in area else 50)

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		destroy()

func receive_damage(dmg: int):
	health_points -= dmg
	if health_points <= 0:
		destroy()

func destroy():
	call_deferred("queue_free")
