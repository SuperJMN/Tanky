extends RigidBody2D

# Signals
signal defeated(killer: Node2D)

# State
var is_destroyed = false
var vertical_speed = 100.0
var horizontal_speed = 0.0

# Timer for auto-explosion
var explosion_timer: Timer

# Sprites
@onready var sprite = $Sprite2D
@onready var detection_area = $DetectionArea

func _ready():
	# Setup physics
	gravity_scale = 1.0
	collision_layer = 2  # Enemy layer
	collision_mask = 1 | 4 | 16  # Player, PlayerShot, Explosion layers
	add_to_group("enemy")
	
	# Setup auto-explosion timer
	explosion_timer = Timer.new()
	explosion_timer.one_shot = true
	explosion_timer.wait_time = 3.0
	explosion_timer.timeout.connect(_on_explosion_timer_timeout)
	add_child(explosion_timer)
	explosion_timer.start()
	
	# Connect detection area for shots
	if detection_area:
		detection_area.area_entered.connect(_on_shot_detected)
	
	# Set initial velocity
	linear_velocity = Vector2(0, vertical_speed)

func _physics_process(delta):
	# Check collisions
	var bodies = get_colliding_bodies()
	for body in bodies:
		if body.is_in_group("explosion"):
			# Chain reaction - explode after delay
			await get_tree().create_timer(0.1).timeout
			destroy_by(body)
			return
		elif body is RigidBody2D and body.is_in_group("enemy"):
			# Bomb-to-bomb collision physics
			var x1 = body.position.x + 16
			var x2 = position.x + 16
			var y1 = body.position.y + 16
			var y2 = position.y + 16
			
			var xr = x2 - x1
			var yr = y2 - y1
			
			var impulse_x = coerce(200.0 / xr) if xr != 0 else 0
			var impulse_y = coerce(200.0 / yr) if yr != 0 else 0
			
			apply_impulse(Vector2(impulse_x, impulse_y))
	
	# Check if touching ground
	if is_touching_ground():
		# Add friction when on ground
		linear_velocity.x /= 2
		
		# Stop small movements
		if abs(linear_velocity.x) < 5:
			linear_velocity.x = 0

func is_touching_ground() -> bool:
	return position.y >= Constants.ground_top - 16

func _on_explosion_timer_timeout():
	destroy_by(self)

func _on_shot_detected(area):
	if area.is_in_group("player_shot"):
		if "shooter" in area:
			destroy_by(area.shooter)
		else:
			destroy_by(area)

func coerce(v: float) -> float:
	return 0.0 if is_inf(v) else v

func destroy_by(killer):
	if is_destroyed:
		return
	
	is_destroyed = true
	
	# Create explosion: ground when on floor, aerial otherwise
	var scene_path := "res://scenes/effects/explosion.tscn" if is_touching_ground() else "res://scenes/effects/aerial_explosion.tscn"
	var explosion_scene = load(scene_path)
	
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		if is_touching_ground():
			# Align ground explosion with bomb base (start from ground top)
			var h := 0.0
			var cs: CollisionShape2D = explosion.get_node_or_null("CollisionShape2D")
			if cs and cs.shape is RectangleShape2D:
				h = (cs.shape as RectangleShape2D).size.y / 2.0
			explosion.position = Vector2(position.x, Constants.ground_top - h)
		else:
			explosion.position = position
		get_parent().call_deferred("add_child", explosion)
	
	defeated.emit(killer)
	call_deferred("queue_free")
