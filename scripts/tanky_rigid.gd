extends RigidBody2D

# Signals
signal died

# Constants
const SIZE = 32
const JUMP_IMPULSE = -6000.0
const MOTOR_TORQUE = 6000.0
const BRAKE_TORQUE = 1200.0
const MAX_ANGULAR_SPEED = 60.0
const WHEEL_ANG_ACCEL = 200.0
const WHEEL_PUSH = 25.0
const SHOOT_OFFSET = Vector2(16, -8)
const JUMP_ANIM_VERTICAL_SPEED = 35.0
const WALK_ANIM_SPEED_THRESHOLD = 5.0
const WALK_ANIM_THROTTLE_THRESHOLD = 0.1
const WALK_ANIM_SPEED_MIN = 0.5
const WALK_ANIM_SPEED_MAX = 2.4
const WALK_ANIM_SMOOTH = 0.18
const WALK_ANIM_DEBUG = false
const WALK_ANIM_DEBUG_INTERVAL = 24

# State
var health_points: int = 10
var live_status := "alive"
var current_weapon := 0
var can_shoot := true
var shoot_cooldown_timer: Timer
var throttle := 0.0

# Nodes
@onready var chassis: Node2D = $Chassis
@onready var animated_sprite: AnimatedSprite2D = $Chassis/AnimatedSprite2D
@onready var front_wheel: RigidBody2D = $FrontWheel
@onready var rear_wheel: RigidBody2D = $RearWheel
@onready var jump_sound: AudioStreamPlayer = $JumpSound
@onready var walk_sound: AudioStreamPlayer = $WalkSound
@onready var die_sound: AudioStreamPlayer = $DieSound

func _ready():
	# Layers: 1 Player; Masks: 2 Ground | 16 Explosion | 2 Enemy via Areas
	collision_layer = 1
	collision_mask = 2 | 16 | 2
	can_sleep = false
	
	front_wheel.can_sleep = false
	rear_wheel.can_sleep = false
	front_wheel.contact_monitor = true
	front_wheel.max_contacts_reported = 4
	rear_wheel.contact_monitor = true
	rear_wheel.max_contacts_reported = 4
	
	# Timer for shooting
	shoot_cooldown_timer = Timer.new()
	shoot_cooldown_timer.one_shot = true
	shoot_cooldown_timer.timeout.connect(_on_shoot_cooldown_timeout)
	add_child(shoot_cooldown_timer)

func _physics_process(delta):
	if live_status != "alive":
		return
	
	_handle_input(delta)
	_apply_drive(delta)
	_limit_speeds()
	_update_animation()
	_check_contacts_for_damage()

func _handle_input(delta):
	var desired := 0.0
	if Input.is_action_pressed("move_right"):
		desired += 1.0
	if Input.is_action_pressed("move_left"):
		desired -= 1.0
	throttle = lerp(throttle, desired, clamp(12.0 * delta, 0.0, 1.0))
	
	if Input.is_action_just_pressed("jump"):
		# small upward impulse
		apply_impulse(Vector2(0, JUMP_IMPULSE))
		if jump_sound:
			jump_sound.play()
		if walk_sound and walk_sound.playing:
			walk_sound.stop()
	
	if Input.is_action_pressed("shoot"):
		shoot_request()
	if Input.is_action_just_pressed("switch_weapon"):
		switch_weapon()
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _apply_drive(delta):
	# Apply torque to wheels
	var t = throttle * MOTOR_TORQUE
	if abs(throttle) < 0.05:
		# light braking when no throttle
		var brake = BRAKE_TORQUE
		front_wheel.apply_torque_impulse(-sign(front_wheel.angular_velocity) * brake)
		rear_wheel.apply_torque_impulse(-sign(rear_wheel.angular_velocity) * brake)
	else:
		front_wheel.apply_torque_impulse(t)
		rear_wheel.apply_torque_impulse(t)
		# Ensure spin even if impulses are damped
		front_wheel.angular_velocity += throttle * WHEEL_ANG_ACCEL * delta
		rear_wheel.angular_velocity += throttle * WHEEL_ANG_ACCEL * delta
		# Small linear push to help start movement (replaced by friction once moving)
		var wp = throttle * WHEEL_PUSH
		front_wheel.apply_central_impulse(Vector2(wp, 0))
		rear_wheel.apply_central_impulse(Vector2(wp, 0))
	
	# Traction is produced by wheel torque + friction; no artificial body push
	
	# servo sound (approx ground check by low vertical speed)
	var moving = abs(t) > 0.01 and abs(linear_velocity.y) < 150.0
	if moving:
		if walk_sound and not walk_sound.playing:
			walk_sound.play()
	else:
		if walk_sound and walk_sound.playing:
			walk_sound.stop()

func _limit_speeds():
	front_wheel.angular_velocity = clamp(front_wheel.angular_velocity, -MAX_ANGULAR_SPEED, MAX_ANGULAR_SPEED)
	rear_wheel.angular_velocity = clamp(rear_wheel.angular_velocity, -MAX_ANGULAR_SPEED, MAX_ANGULAR_SPEED)

func _update_animation():
	var on_ground: bool = _wheel_in_contact(front_wheel) or _wheel_in_contact(rear_wheel)
	var horizontal_speed: float = linear_velocity.x
	if horizontal_speed < 0.0:
		horizontal_speed = -horizontal_speed
	var vertical_speed_abs: float = linear_velocity.y
	if vertical_speed_abs < 0.0:
		vertical_speed_abs = -vertical_speed_abs
	var airborne_jump: bool = not on_ground and vertical_speed_abs > JUMP_ANIM_VERTICAL_SPEED
	var target_speed_scale: float = 1.0
	if airborne_jump:
		if animated_sprite.animation != "jump":
			animated_sprite.play("jump")
	elif on_ground and horizontal_speed > WALK_ANIM_SPEED_THRESHOLD:
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
		var throttle_abs: float = throttle
		if throttle_abs < 0.0:
			throttle_abs = -throttle_abs
		if throttle_abs > WALK_ANIM_THROTTLE_THRESHOLD:
			var front_speed: float = front_wheel.angular_velocity
			if front_speed < 0.0:
				front_speed = -front_speed
			var rear_speed: float = rear_wheel.angular_velocity
			if rear_speed < 0.0:
				rear_speed = -rear_speed
			var wheel_speed: float = front_speed if front_speed > rear_speed else rear_speed
			var normalized: float = 0.0
			if MAX_ANGULAR_SPEED > 0.0:
				normalized = wheel_speed / MAX_ANGULAR_SPEED
				if normalized < 0.0:
					normalized = 0.0
				elif normalized > 1.0:
					normalized = 1.0
			target_speed_scale = WALK_ANIM_SPEED_MIN + (WALK_ANIM_SPEED_MAX - WALK_ANIM_SPEED_MIN) * normalized
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
	animated_sprite.speed_scale += (target_speed_scale - animated_sprite.speed_scale) * WALK_ANIM_SMOOTH
	if WALK_ANIM_DEBUG and Engine.get_process_frames() % WALK_ANIM_DEBUG_INTERVAL == 0:
		print("[walk anim] vel_x=", horizontal_speed,
			" throttle=", throttle,
			" target=", target_speed_scale,
			" current=", animated_sprite.speed_scale,
			" on_ground=", on_ground)

func _wheel_in_contact(wheel: RigidBody2D) -> bool:
	return wheel and wheel.get_contact_count() > 0

func _check_contacts_for_damage():
	if not contact_monitor:
		return
	var bodies = get_colliding_bodies()
	for body in bodies:
		if body and (body.is_in_group("enemy") or body.is_in_group("explosion")):
			receive_damage(10)

func shoot_request():
	if can_shoot:
		shoot()
		can_shoot = false
		shoot_cooldown_timer.start(get_current_weapon_cooldown())

func shoot():
	var shot = create_shot()
	if shot:
		shot.position = global_position + SHOOT_OFFSET.rotated(global_rotation)
		get_parent().add_child(shot)

func create_shot():
	var shot_scene = load("res://scenes/shots/regular_shot.tscn")
	if shot_scene:
		var shot = shot_scene.instantiate()
		shot.shooter = self
		return shot
	return null

func get_current_weapon_cooldown() -> float:
	match current_weapon:
		0: return 0.3
		1: return 0.5
		2: return 0.15
	return 0.3

func _on_shoot_cooldown_timeout():
	can_shoot = true

func switch_weapon():
	current_weapon = (current_weapon + 1) % 3

func receive_damage(damage: int):
	if live_status == "dead":
		return
	health_points -= damage
	if health_points <= 0:
		die()

func die():
	if live_status != "dead":
		linear_velocity = Vector2.ZERO
		if die_sound:
			die_sound.play()
		died.emit()
		live_status = "dead"

func respawn():
	health_points = 10
	global_position = Vector2(100, 300)
	var tween = create_tween()
	tween.set_loops(30)
	tween.tween_property(animated_sprite, "visible", false, 0.05)
	tween.tween_property(animated_sprite, "visible", true, 0.05)
