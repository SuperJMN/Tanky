extends Area2D

# Signals
signal defeated(killer: Node2D)

# Movement
var horizontal_speed = 200.0
var vertical_speed = 0.0

# Stats
var hit_points = 25
var damage = 50
var is_destroyed = false

# Bomb dropping
var bomb_scene = preload("res://scenes/enemies/bomb.tscn")
var bomb_timer: Timer

# Sprites
@onready var sprite = $Sprite2D

func _ready():
	# Setup collision
	collision_layer = 2  # Enemy layer
	collision_mask = 4   # PlayerShot layer
	add_to_group("enemy")
	
	# Random vertical speed
	vertical_speed = randf_range(-120, 100)
	
	# Setup bomb dropping timer with random intervals
	bomb_timer = Timer.new()
	bomb_timer.one_shot = false
	bomb_timer.wait_time = randf_range(0.2, 1.8)
	bomb_timer.timeout.connect(_on_bomb_timer_timeout)
	add_child(bomb_timer)
	bomb_timer.start()
	
	# Connect collision
	area_entered.connect(_on_area_entered)

func _physics_process(delta):
	# Move left
	position.x -= horizontal_speed * delta
	position.y += vertical_speed * delta
	
	# Decelerate near vertical limits
	if is_near_vertical_limits():
		vertical_speed /= 1.02
	
	# Remove if out of bounds
	if is_out_of_bounds():
		call_deferred("queue_free")

func is_near_vertical_limits() -> bool:
	var threshold = 50
	return position.y + threshold >= Constants.ground_top or position.y - threshold <= 0

func is_out_of_bounds() -> bool:
	var viewport_rect = get_viewport_rect()
	return position.x < -100 or position.x > viewport_rect.size.x + 100

func _on_bomb_timer_timeout():
	# Drop bomb if not too close to ground
	if position.y + 64 + 20 < Constants.ground_top:
		drop_bomb()
	
	# Reset timer with new random interval
	bomb_timer.wait_time = randf_range(0.2, 1.8)

func drop_bomb():
	var bomb = bomb_scene.instantiate()
	bomb.position = position + Vector2(0, 32)
	get_parent().add_child(bomb)
	bomb.defeated.connect(_on_bomb_defeated)

func _on_bomb_defeated(killer: Node2D):
	get_parent().enemy_defeated.emit("Bomb", killer)

func _on_area_entered(area):
	if area.is_in_group("player_shot"):
		var shot = area
		receive_damage_from(shot.shooter, shot.damage)

func receive_damage_from(damager: Node2D, dmg: int):
	hit_points -= dmg
	position.x += float(dmg) / 3.0
	
	if hit_points <= 0:
		destroy_by(damager)

func destroy_by(killer: Node2D):
	if is_destroyed:
		return
	
	is_destroyed = true
	
	# Create explosion (using ground explosion for now)
	var explosion_scene = load("res://scenes/effects/explosion.tscn")
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.position = position
		get_parent().call_deferred("add_child", explosion)
	
	defeated.emit(killer)
	call_deferred("queue_free")
