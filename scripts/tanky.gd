extends CharacterBody2D

# Signals
signal died

# Constants
const SIZE = 32
const JUMP_ACCELERATION = -800.0

# Track/physics params (traction-based)
const MASS = 12.0                           # kg (snappy response)
const MOTOR_FORCE = 4500.0                  # stronger drive force
const MU_STATIC = 1.2                       # higher grip to avoid wheelspin
const MU_KINETIC = 1.0                      # better while slipping
const ROLLING_RESISTANCE_COEFF = 0.004      # low rolling drag
const AIR_DRAG = 0.001                      # low air drag
const AIR_CONTROL_FORCE = 320.0             # a bit more control in air
const MAX_SPEED = 320.0                     # higher top speed
const THROTTLE_RESPONSE = 35.0              # faster throttle tracking
const LOW_SPEED_TORQUE_GAIN = 3.0           # extra torque at low speed
const TORQUE_PEAK_SPEED = 140.0             # speed below which torque is boosted
const MAX_BRAKE_FORCE = 12000.0             # hard braking cap
const COAST_BRAKE_FORCE = 3000.0            # brake when throttle ~ 0
const REVERSE_BRAKE_MULT = 2.0              # stronger when reversing throttle

# Visual tilt params
const MAX_TILT = deg_to_rad(28.0)
const TILT_LERP_SPEED = 12.0

# Animation params
const WALK_SPEED_THRESHOLD = 5.0
const WALK_ANIM_SPEED_MIN = 0.35
const WALK_ANIM_SPEED_MAX = 2.6
const WALK_ANIM_SMOOTH = 0.2
const WALK_ANIM_DEBUG = false
const WALK_ANIM_DEBUG_INTERVAL = 12

# Collider geometry (axis-aligned box 32x32)
const HALF_SIZE = SIZE / 2.0
const EXTENTS = Vector2(HALF_SIZE, HALF_SIZE)
const GROUND_EPS = 0.5

# State enums
enum JumpState { LANDED, JUMPING }

# State variables
var jump_state = JumpState.LANDED
var health_points = 10
var is_visible_override = true
var live_status = "alive"

# Locomotion state
var throttle := 0.0                         # -1..1 desired track effort
var is_slipping := false

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
@onready var chassis = $Chassis
@onready var animated_sprite = $Chassis/AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var front_wheel: RayCast2D = $FrontWheel
@onready var rear_wheel: RayCast2D = $RearWheel

func _ready():
	# Setup collision
	collision_layer = 1  # Player layer
	collision_mask = 1 | 2 | 16  # Ground, Enemy and Explosion layers
	# Improve slope handling
	floor_max_angle = deg_to_rad(65)
	floor_snap_length = 18.0  # Re-enabled snap for CharacterBody2D
	
	# Setup shoot cooldown
	shoot_cooldown_timer = Timer.new()
	shoot_cooldown_timer.one_shot = true
	shoot_cooldown_timer.timeout.connect(_on_shoot_cooldown_timeout)
	add_child(shoot_cooldown_timer)
	
	# Initialize weapons
	initialize_weapons()

func _physics_process(delta):
	# Gravity + vertical motion
	if not is_on_floor():
		velocity.y += Constants.GRAVITY * delta
		jump_state = JumpState.JUMPING
	else:
		if jump_state == JumpState.JUMPING:
			land()
		velocity.y = 0
	
	# Input and traction-based horizontal physics
	if live_status == "alive":
		handle_input(delta)
		apply_track_physics(delta)
	
	# Move and detect collisions
	move_and_slide()
	
	# Track-based suspension disabled (use CharacterBody2D snap)
	# adjust_suspension(delta)
	
	# Check collisions con enemigos/explosiones
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and (collider.is_in_group("enemy") or collider.is_in_group("explosion")):
			receive_damage(10)
	
	# Update animation and visual tilt
	update_animation()
	update_tilt(delta)

func handle_input(delta):
	# Read desired throttle from input (left/right). Smooth to avoid instant changes
	var desired := 0.0
	if Input.is_action_pressed("move_right"):
		desired += 1.0
	if Input.is_action_pressed("move_left"):
		desired -= 1.0
	throttle = lerp(throttle, desired, clamp(THROTTLE_RESPONSE * delta, 0.0, 1.0))
	
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_ACCELERATION
		jump_state = JumpState.JUMPING
		if jump_sound:
			jump_sound.play()
		if walk_sound:
			walk_sound.stop()
	
	# Halt jump early if button released
	if Input.is_action_just_released("jump") and jump_state == JumpState.JUMPING and velocity.y < 0:
		velocity.y *= 0.5
	
	# Shoot
	if Input.is_action_pressed("shoot"):
		shoot_request()
	
	# Switch weapon
	if Input.is_action_just_pressed("switch_weapon"):
		switch_weapon()
	
	# Quit
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func apply_track_physics(delta):
	# Compute normal force (approx). If on floor, N ~= m*g projected on floor normal
	var N := 0.0
	if is_on_floor():
		var n = get_floor_normal()
		var cos_theta = n.dot(Vector2.UP)
		N = MASS * Constants.GRAVITY * max(cos_theta, 0.0)
		if N == 0.0:
			N = MASS * Constants.GRAVITY
	
	var drive_force := 0.0
	var resist_force := 0.0
	is_slipping = false
	
	if is_on_floor():
		# Desired motor force with low-speed torque boost
		var speed = abs(velocity.x)
		var torque_boost = 1.0 + LOW_SPEED_TORQUE_GAIN * max(0.0, 1.0 - speed / TORQUE_PEAK_SPEED)
		var motor = throttle * MOTOR_FORCE * torque_boost
		# Traction-limited drive (static vs kinetic friction)
		var traction_limit = MU_STATIC * N
		if abs(motor) <= traction_limit:
			drive_force = motor
		else:
			is_slipping = true
			drive_force = MU_KINETIC * N * sign(motor)
		# Rolling resistance opposes motion
		if abs(velocity.x) > 0.1:
			resist_force += -ROLLING_RESISTANCE_COEFF * N * sign(velocity.x)
		# Braking assistance
		var v_sign = sign(velocity.x)
		var t_sign = sign(throttle)
		if abs(throttle) < 0.05 and abs(velocity.x) > 0.1:
			resist_force += -min(COAST_BRAKE_FORCE, MU_KINETIC * N) * v_sign
		elif v_sign != 0 and t_sign != 0 and v_sign != t_sign:
			# Actively braking to reverse direction
			resist_force += -min(MAX_BRAKE_FORCE * REVERSE_BRAKE_MULT, MU_KINETIC * N) * v_sign
	else:
		# In air: limited control
		drive_force = throttle * AIR_CONTROL_FORCE
	
	# Aerodynamic/viscous drag
	resist_force += -AIR_DRAG * velocity.x * abs(velocity.x)
	
	# Total and integrate
	var ax = (drive_force + resist_force) / MASS
	velocity.x += ax * delta
	
	# Clamp max speed
	velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)
	
	# Servo sound: play only when driving on ground and not jumping
	var moving = is_on_floor() and jump_state != JumpState.JUMPING and abs(throttle) > 0.1 and abs(velocity.x) > 1.0
	if moving:
		if walk_sound and not walk_sound.playing:
			walk_sound.play()
	else:
		if walk_sound and walk_sound.playing:
			walk_sound.stop()

func adjust_suspension(delta):
	# Disabled: handled by floor snap
	return
	# Read wheel contact points
	var front_hit = front_wheel.is_colliding()
	var rear_hit = rear_wheel.is_colliding()
	
	if front_hit and rear_hit:
		# Both wheels on ground: align body center to the ground line along its normal (vector correction)
		var fp = front_wheel.get_collision_point()
		var rp = rear_wheel.get_collision_point()
		var avg = (fp + rp) * 0.5
		var tangent = (fp - rp).normalized()
		var n = Vector2(-tangent.y, tangent.x)
		if n.y > 0: n = -n
		var r = abs(n.x) * EXTENTS.x + abs(n.y) * EXTENTS.y
		var target_center = avg + n * r
		var correction_vec = target_center - global_position
		var step = correction_vec * 20.0 * delta
		step.x = clamp(step.x, -4.0, 4.0)
		step.y = clamp(step.y, -5.0, 5.0)
		global_position += step
	elif front_hit:
		# Only front wheel: align center to that contact (vector correction)
		var fp = front_wheel.get_collision_point()
		var n = front_wheel.get_collision_normal()
		if n.y > 0: n = -n
		var r = abs(n.x) * EXTENTS.x + abs(n.y) * EXTENTS.y
		var target_center = fp + n * r
		var correction_vec = target_center - global_position
		var step = correction_vec * 18.0 * delta
		step.x = clamp(step.x, -3.0, 3.0)
		step.y = clamp(step.y, -4.0, 4.0)
		global_position += step
	elif rear_hit:
		# Only rear wheel: align center to that contact (vector correction)
		var rp = rear_wheel.get_collision_point()
		var n = rear_wheel.get_collision_normal()
		if n.y > 0: n = -n
		var r = abs(n.x) * EXTENTS.x + abs(n.y) * EXTENTS.y
		var target_center = rp + n * r
		var correction_vec = target_center - global_position
		var step = correction_vec * 18.0 * delta
		step.x = clamp(step.x, -3.0, 3.0)
		step.y = clamp(step.y, -4.0, 4.0)
		global_position += step

func update_tilt(delta):
	var target := rotation
	if front_wheel and rear_wheel and front_wheel.is_colliding() and rear_wheel.is_colliding():
		var fp = front_wheel.get_collision_point()
		var rp = rear_wheel.get_collision_point()
		target = clamp(atan2(fp.y - rp.y, fp.x - rp.x), -MAX_TILT, MAX_TILT)
	elif front_wheel and front_wheel.is_colliding():
		var n = front_wheel.get_collision_normal()
		var tangent = Vector2(-n.y, n.x)
		target = clamp(atan2(tangent.y, tangent.x), -MAX_TILT, MAX_TILT)
	elif rear_wheel and rear_wheel.is_colliding():
		var n2 = rear_wheel.get_collision_normal()
		var t2 = Vector2(-n2.y, n2.x)
		target = clamp(atan2(t2.y, t2.x), -MAX_TILT, MAX_TILT)
	elif is_on_floor():
		var n3 = get_floor_normal()
		var t3 = Vector2(-n3.y, n3.x)
		target = clamp(atan2(t3.y, t3.x), -MAX_TILT, MAX_TILT)
	else:
		target = 0.0
	rotation = lerp_angle(rotation, target, clamp(TILT_LERP_SPEED * delta, 0.0, 1.0))
	chassis.rotation = 0.0

func update_animation():
	# Automatically update animation based on state
	var horizontal_speed: float = absf(velocity.x)
	var is_ground_drive: bool = is_on_floor() and jump_state != JumpState.JUMPING and absf(throttle) > 0.05
	var target_speed_scale: float = 1.0
	if jump_state == JumpState.JUMPING:
		if animated_sprite.animation != "jump":
			animated_sprite.play("jump")
	elif horizontal_speed > WALK_SPEED_THRESHOLD:
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
		if is_ground_drive:
			var denom: float = max(MAX_SPEED - WALK_SPEED_THRESHOLD, 1.0)
			var speed_ratio: float = clampf((horizontal_speed - WALK_SPEED_THRESHOLD) / denom, 0.0, 1.0)
			var eased_ratio: float = sqrt(speed_ratio)
			target_speed_scale = WALK_ANIM_SPEED_MIN + (WALK_ANIM_SPEED_MAX - WALK_ANIM_SPEED_MIN) * eased_ratio
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
	animated_sprite.speed_scale += (target_speed_scale - animated_sprite.speed_scale) * WALK_ANIM_SMOOTH
	if WALK_ANIM_DEBUG:
		var frame_number: int = Engine.get_process_frames()
		if frame_number % WALK_ANIM_DEBUG_INTERVAL == 0:
			print(
				"[walk anim] frame=", frame_number,
				" vel=", horizontal_speed,
				" target=", target_speed_scale,
				" current=", animated_sprite.speed_scale,
				" ground=", is_ground_drive
			)

func land():
	jump_state = JumpState.LANDED
	# Walk sound will resume automatically if moving

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
