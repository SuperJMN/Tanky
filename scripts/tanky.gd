extends CharacterBody2D

# Signals
signal died

# Constants
const SIZE = 32
const JUMP_ACCELERATION = -800.0
const WALK_SPEED = 200.0

# State enums
enum JumpState { LANDED, JUMPING }

# State variables
var jump_state = JumpState.LANDED
var health_points = 10
var is_visible_override = true
var live_status = "alive"

# Weapon system
var current_weapon = 0
var weapon_factories = []
var can_shoot = true
var shoot_cooldown_timer: Timer

# Audio
@onready var jump_sound = $JumpSound
@onready var walk_sound = $WalkSound
@onready var die_sound = $DieSound

# Sprites
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	# Setup collision
	collision_layer = 1  # Player layer
	collision_mask = 1 | 2 | 16  # Ground, Enemy and Explosion layers
	
	# Position at ground (will be set by initial scene position)
	
	# Setup shoot cooldown
	shoot_cooldown_timer = Timer.new()
	shoot_cooldown_timer.one_shot = true
	shoot_cooldown_timer.timeout.connect(_on_shoot_cooldown_timeout)
	add_child(shoot_cooldown_timer)
	
	# Initialize weapons
	initialize_weapons()

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += Constants.GRAVITY * delta
		jump_state = JumpState.JUMPING
	else:
		if jump_state == JumpState.JUMPING:
			land()
		velocity.y = 0
	
	# Handle input
	if live_status == "alive":
		handle_input(delta)
	
	# Move and detect collisions
	move_and_slide()
	
	# Check collisions
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and (collider.is_in_group("enemy") or collider.is_in_group("explosion")):
			receive_damage(10)
	
	# Update animation
	update_animation()

func handle_input(delta):
	# Horizontal movement
	var moving = false
	if Input.is_action_pressed("move_right"):
		velocity.x = WALK_SPEED
		moving = true
	elif Input.is_action_pressed("move_left"):
		velocity.x = -WALK_SPEED
		moving = true
	else:
		velocity.x = 0
	
	# Update walk sound
	if moving and jump_state != JumpState.JUMPING:
		if walk_sound and not walk_sound.playing:
			walk_sound.play()
	else:
		if walk_sound and walk_sound.playing:
			walk_sound.stop()
	
	# Jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_ACCELERATION
			jump_state = JumpState.JUMPING
			if jump_sound:
				jump_sound.play()
			if walk_sound:
				walk_sound.stop()
	
	# Halt jump early if button released
	if Input.is_action_just_released("jump"):
		if jump_state == JumpState.JUMPING and velocity.y < 0:
			velocity.y /= 2
	
	# Shoot
	if Input.is_action_pressed("shoot"):
		shoot_request()
	
	# Switch weapon
	if Input.is_action_just_pressed("switch_weapon"):
		switch_weapon()
	
	# Quit
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func update_animation():
	# Automatically update animation based on state
	if jump_state == JumpState.JUMPING:
		if animated_sprite.animation != "jump":
			animated_sprite.play("jump")
	elif abs(velocity.x) > 0:
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

func land():
	jump_state = JumpState.LANDED
	# Walk sound will resume automatically in handle_input if moving

func shoot_request():
	if can_shoot:
		shoot()
		can_shoot = false
		shoot_cooldown_timer.start(get_current_weapon_cooldown())

func shoot():
	var shot = create_shot()
	if shot:
		shot.position = position + Vector2(SIZE, SIZE / 2)
		get_parent().add_child(shot)

func create_shot():
	# TODO: Load and instantiate appropriate shot scene based on current_weapon
	var shot_scene = load("res://scenes/shots/regular_shot.tscn")
	if shot_scene:
		var shot = shot_scene.instantiate()
		shot.shooter = self
		return shot
	return null

func get_current_weapon_cooldown() -> float:
	# Different weapons have different cooldowns
	match current_weapon:
		0: return 0.3  # Regular shot
		1: return 0.5  # Fireball
		2: return 0.15 # Small shot
	return 0.3

func _on_shoot_cooldown_timeout():
	can_shoot = true

func switch_weapon():
	current_weapon = (current_weapon + 1) % 3

func initialize_weapons():
	# Weapon system initialized
	pass

func receive_damage(damage: int):
	if live_status == "dead":
		return
	
	health_points -= damage
	if health_points <= 0:
		die()

func die():
	if live_status != "dead":
		velocity.x = 0
		if die_sound:
			die_sound.play()
		died.emit()
		live_status = "dead"

func respawn():
	health_points = 10
	position = Vector2(100, Constants.ground_top - SIZE)
	
	# Blink effect
	var tween = create_tween()
	tween.set_loops(30)
	tween.tween_property(animated_sprite, "visible", false, 0.05)
	tween.tween_property(animated_sprite, "visible", true, 0.05)
	tween.finished.connect(_on_respawn_finished)

func _on_respawn_finished():
	animated_sprite.visible = true
	live_status = "alive"
