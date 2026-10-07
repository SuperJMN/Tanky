extends Node2D
class_name Tanky

## Emitted whenever Tanky loses health.
signal health_changed(health: int, max_health: int)
## Emitted once when Tanky is destroyed or falls off the level.
signal died

const PIXELS_PER_METER := 100.0
const BODY_LENGTH := 50.0  # 0.5m * 100px/m
const MIN_SPEED := 150.0  # 3 body lengths/s
const MAX_SPEED := 500.0  # 10 body lengths/s
const ACCEL_TIME := 2  # seconds to reach max speed
const DRIVE_TORQUE := 50000.0
const BRAKE_TORQUE := 10000.0
const DRIVE_FORCE := 650.0
const AIR_ACCEL := 450.0  # px/s² of horizontal steering while airborne
const WHEEL_RADIUS := 8.4  # wheel collision radius (12 px circle scaled by 0.7)
const AIR_WHEEL_SYNC := 6000.0  # torque per rad/s that keeps the wheels rolling in the air
const JUMP_HEIGHT := 150.0  # 1.5 m
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const PROJECTILE_SPEED := 700.0
const PROJECTILE_INHERIT_VEL := 0.25
const GUN_MIN_DEG := -60.0
const GUN_MAX_DEG := 10.0
const GUN_AIM_SPEED_DEG := 90.0
const TRACKS_DROP_OFFSET := 5.0
const TRACKS_RETURN_SPEED := 80.0
const EXPLOSION_SCENE := preload("res://scenes/explosion.tscn")

# Damage
const MAX_HEALTH := 4  # hits Tanky can take; the last one destroys him
const INVULNERABLE_TIME := 1.5  # s of blinking after a hit, while nothing can hurt him
const HIT_STUN_TIME := 0.35  # s without control after a hit, so the knockback reads
const HIT_KNOCKBACK := Vector2(260.0, -300.0)  # velocity away from the hit, px/s
const BLINK_PERIOD := 0.08
const DEATH_EXPLOSION_SCALE := 1.6

# Head bobbing
const HEAD_BOB_AMPLITUDE := 0.8
const HEAD_BOB_FREQ := 3.0
const HEAD_BOB_SPEED_THRESHOLD := 40.0

# Air auto-balance controller (scaled by mass)
const AIR_TILT_KP_PER_MASS := 800.0
const AIR_TILT_KD_PER_MASS := 120.0
const AIR_MAX_TORQUE_PER_MASS := 1500.0
const ANGULAR_VEL_LIMIT := 7.0
# Grounding filters
const GROUND_NORMAL_DOT_THRESHOLD := 0.6  # Accept surfaces close to "up"
const GROUNDED_ASCENT_MAX := -30.0        # Consider grounded only if not moving up faster than this (px/s)

@export_node_path("RigidBody2D") var chassis_path: NodePath
@export_node_path("RigidBody2D") var front_wheel_path: NodePath
@export_node_path("RigidBody2D") var rear_wheel_path: NodePath
@export_node_path("AnimatedSprite2D") var sprite_path: NodePath
@export_node_path("Node2D") var gun_path: NodePath
@export_node_path("Marker2D") var muzzle_path: NodePath
@export_node_path("AudioStreamPlayer2D") var jump_player_path: NodePath
@export_node_path("AudioStreamPlayer2D") var shoot_player_path: NodePath
@export_node_path("AudioStreamPlayer2D") var cannon_move_player_path: NodePath
@export_node_path("RayCast2D") var ground_cast_front_path: NodePath
@export_node_path("RayCast2D") var ground_cast_rear_path: NodePath
@export_node_path("Camera2D") var camera_path: NodePath
@export_node_path("Timer") var shoot_timer_path: NodePath
@export_node_path("Node2D") var head_rig_path: NodePath
@export_node_path("Node") var antenna_path: NodePath
@export_node_path("Node") var eye_path: NodePath
@export_node_path("Area2D") var hurtbox_path: NodePath
@export_node_path("AudioStreamPlayer2D") var hurt_player_path: NodePath

@onready var chassis: RigidBody2D = get_node(chassis_path)
@onready var front_wheel: RigidBody2D = get_node(front_wheel_path)
@onready var rear_wheel: RigidBody2D = get_node(rear_wheel_path)
@onready var sprite: AnimatedSprite2D = get_node(sprite_path)
@onready var gun: Node2D = get_node(gun_path)
@onready var muzzle: Marker2D = get_node(muzzle_path)
@onready var jump_player: AudioStreamPlayer2D = get_node(jump_player_path)
@onready var shoot_player: AudioStreamPlayer2D = get_node(shoot_player_path)
@onready var cannon_move_player: AudioStreamPlayer2D = get_node(cannon_move_player_path)
@onready var ground_cast_front: RayCast2D = get_node(ground_cast_front_path)
@onready var ground_cast_rear: RayCast2D = get_node(ground_cast_rear_path)
@onready var ground_casts: Array[RayCast2D] = [ground_cast_front, ground_cast_rear]
@onready var camera: Camera2D = get_node(camera_path)
@onready var shoot_timer: Timer = get_node(shoot_timer_path)
@onready var head_rig: Node2D = get_node(head_rig_path)
@onready var antenna: Node = get_node(antenna_path)
@onready var eye: Node = get_node(eye_path)
@onready var hurtbox: Hurtbox = get_node(hurtbox_path)
@onready var hurt_player: AudioStreamPlayer2D = get_node(hurt_player_path)
@onready var _rig: Array[RigidBody2D] = [chassis, front_wheel, rear_wheel]

var health := MAX_HEALTH

var _facing := 1
var _accel_time := 0.0
var _last_move_dir := 0.0
var _head_bob_t := 0.0
var _head_rig_base_y := 0.0
var _blink_rng := RandomNumberGenerator.new()
var _sprite_base_y := 0.0
var _tracks_offset := 0.0
var _in_tree := true
var _dead := false
var _invulnerable_left := 0.0
var _stun_left := 0.0

func _ready() -> void:

	sprite.play("idle")
	camera.make_current()
	hurtbox.hurt.connect(take_hit)
	
	# Cache head rig base position
	if head_rig:
		_head_rig_base_y = head_rig.position.y
	_sprite_base_y = sprite.position.y
	
	# Increase angular damping to reduce wobble
	chassis.angular_damp = 4.0
	front_wheel.angular_damp = 2.4
	rear_wheel.angular_damp = 2.4
	
	# En headless evitamos timers/sonidos de cosmetica
	if OS.has_feature("headless") or (Engine.has_singleton("DisplayServer") and DisplayServer.get_name() == "headless"):
		return
	
	# Initialize eye/blink behavior (only if AnimatedSprite2D is available)
	_blink_rng.randomize()
	if eye and eye is AnimatedSprite2D:
		var e := eye as AnimatedSprite2D
		e.stop()
		e.frame = 0
		_start_blink_loop()

# Clamp the follow camera to a level's world-space bounds. The top stays open for jumps.
# Camera2D applies limits before its offset, so compensate for it.
func set_camera_limits(bounds: Rect2) -> void:
	camera.limit_left = floori(bounds.position.x - camera.offset.x)
	camera.limit_right = ceili(bounds.end.x - camera.offset.x)
	camera.limit_bottom = ceili(bounds.end.y - camera.offset.y)

func _physics_process(delta: float) -> void:
	camera.global_position = chassis.global_position
	if _dead:
		return
	_update_damage(delta)
	var has_control := _stun_left <= 0.0
	var move := Input.get_axis("move_left", "move_right") if has_control else 0.0
	var grounded := _is_grounded()
	
	_update_acceleration(move, delta)
	_apply_drive(move, grounded)
	_apply_drag(move, grounded)
	_update_head_bob(grounded, delta)
	_update_gun_aim(delta)
	
	# Air auto-balance: keep chassis near 0° while airborne
	if not grounded:
		var kp := AIR_TILT_KP_PER_MASS * chassis.mass
		var kd := AIR_TILT_KD_PER_MASS * chassis.mass
		var max_torque := AIR_MAX_TORQUE_PER_MASS * chassis.mass
		var tilt := wrapf(chassis.rotation, -PI, PI) # target 0 rad
		var torque := clampf(-kp * tilt - kd * chassis.angular_velocity, -max_torque, max_torque)
		chassis.apply_torque(torque)
		# Prevent extreme spins
		chassis.angular_velocity = clampf(chassis.angular_velocity, -ANGULAR_VEL_LIMIT, ANGULAR_VEL_LIMIT)
	
	if has_control and Input.is_action_just_pressed("jump") and grounded:
		var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
		# Launch every body of the rig at the same speed so the joints do not stretch on take-off
		var takeoff := Vector2.UP * sqrt(2.0 * gravity * JUMP_HEIGHT)
		for body in _rig:
			body.apply_central_impulse(takeoff * body.mass)
		jump_player.play()
		_compress_tracks()
	
	if Input.is_action_pressed("shoot") and shoot_timer.is_stopped():
		_shoot()
	
	_update_facing()
	_update_tracks_suspension(grounded, delta)

func _update_acceleration(move: float, delta: float) -> void:
	if move != 0.0 and sign(move) == sign(_last_move_dir):
		_accel_time = min(_accel_time + delta, ACCEL_TIME)
	else:
		# Resume the speed ramp from the current speed, so pressing again never slows Tanky down
		var speed := chassis.linear_velocity.x * signf(move)
		_accel_time = clampf(inverse_lerp(MIN_SPEED, MAX_SPEED, speed), 0.0, 1.0) * ACCEL_TIME
	_last_move_dir = move

func _current_max_speed() -> float:
	return lerpf(MIN_SPEED, MAX_SPEED, _accel_time / ACCEL_TIME)

func _apply_drive(move: float, grounded: bool) -> void:
	if move == 0.0 or not grounded:
		return
	
	var current_max := _current_max_speed()
	var velocity := chassis.linear_velocity.x
	if abs(velocity) > current_max and sign(velocity) == sign(move):
		return
	
	var torque := DRIVE_TORQUE * move
	front_wheel.apply_torque(torque)
	rear_wheel.apply_torque(torque)

func _apply_drag(move: float, grounded: bool) -> void:
	if not grounded:
		_apply_air_steering(move)
		_sync_wheels_to_chassis()
		return
	
	var drag := (move * _current_max_speed() - chassis.linear_velocity.x) * DRIVE_FORCE
	chassis.apply_central_force(Vector2(drag, 0.0))
	
	if move == 0.0:
		for wheel in [front_wheel, rear_wheel]:
			wheel.apply_torque(-wheel.angular_velocity * BRAKE_TORQUE)

# In the air the motors keep the wheels rolling at the chassis speed, so Tanky lands
# without the tracks grabbing the ground and killing his momentum.
func _sync_wheels_to_chassis() -> void:
	var target_spin := chassis.linear_velocity.x / WHEEL_RADIUS
	for wheel: RigidBody2D in [front_wheel, rear_wheel]:
		wheel.apply_torque((target_spin - wheel.angular_velocity) * AIR_WHEEL_SYNC)

# Airborne momentum is kept (Super Mario Bros. 3 style): with no input Tanky keeps his speed,
# and input only nudges it at AIR_ACCEL, never beyond the current run speed.
func _apply_air_steering(move: float) -> void:
	if move == 0.0:
		return
	var velocity := chassis.linear_velocity.x
	var target := move * _current_max_speed()
	if signf(velocity) == signf(move) and absf(velocity) >= absf(target):
		return
	# Push every body of the rig by its own mass: a force on the chassis alone would drag the
	# wheels through the joints, above its center of mass, and tilt it backwards.
	var accel := Vector2(signf(target - velocity) * AIR_ACCEL, 0.0)
	for body in _rig:
		body.apply_central_force(accel * body.mass)

func _update_head_bob(grounded: bool, delta: float) -> void:
	if not head_rig or not chassis:
		return
	var speed := absf(chassis.linear_velocity.x)
	if grounded and speed > HEAD_BOB_SPEED_THRESHOLD:
		var freq_scale := clampf(speed / 200.0, 0.5, 1.1)
		_head_bob_t += delta * HEAD_BOB_FREQ * freq_scale
		var offset := sin(_head_bob_t * TAU) * HEAD_BOB_AMPLITUDE
		head_rig.position.y = _head_rig_base_y + offset
	else:
		# Smoothly return to base when not walking
		head_rig.position.y = move_toward(head_rig.position.y, _head_rig_base_y, 20.0 * delta)

func _update_gun_aim(delta: float) -> void:
	var axis := Input.get_axis("aim_up", "aim_down")
	if axis != 0.0:
		var new_angle := gun.rotation + deg_to_rad(GUN_AIM_SPEED_DEG) * axis * delta
		gun.rotation = clampf(new_angle, deg_to_rad(GUN_MIN_DEG), deg_to_rad(GUN_MAX_DEG))
		# Start SFX; rely on resource loop settings for looping
		if not OS.has_feature("headless") and not cannon_move_player.playing:
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			cannon_move_player.pitch_scale = rng.randf_range(0.96, 1.06)
			cannon_move_player.play()
	else:
		# Stop SFX when not aiming
		if cannon_move_player.playing:
			cannon_move_player.stop()

# Track compression is purely visual: it offsets the track sprite, never the wheel bodies.
func _compress_tracks() -> void:
	_tracks_offset = TRACKS_DROP_OFFSET
	sprite.position.y = _sprite_base_y + _tracks_offset

func _update_tracks_suspension(grounded: bool, delta: float) -> void:
	if grounded:
		_tracks_offset = move_toward(_tracks_offset, 0.0, TRACKS_RETURN_SPEED * delta)
	sprite.position.y = _sprite_base_y + _tracks_offset

func _shoot() -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	projectile.global_position = muzzle.global_position
	var aim_dir: Vector2 = muzzle.global_transform.x.normalized()
	projectile.velocity = aim_dir * PROJECTILE_SPEED + chassis.linear_velocity * PROJECTILE_INHERIT_VEL
	projectile.shooter = chassis
	get_tree().current_scene.add_child(projectile)
	if not OS.has_feature("headless"):
		shoot_player.play()
	shoot_timer.start()


func is_alive() -> bool:
	return not _dead

## Point enemies aim at: the middle of the hull.
func target_position() -> Vector2:
	return chassis.global_position + Vector2(0.0, -10.0)

## Lose one hit from a hazard at source, unless Tanky is still blinking from the last one.
func take_hit(source: Vector2) -> void:
	if _dead or _invulnerable_left > 0.0:
		return
	health -= 1
	health_changed.emit(health, MAX_HEALTH)
	if health <= 0:
		kill(true)
		return
	_invulnerable_left = INVULNERABLE_TIME
	_stun_left = HIT_STUN_TIME
	hurt_player.play()
	var away := signf(chassis.global_position.x - source.x)
	if away == 0.0:
		away = -1.0
	# Give every body of the rig the same velocity, so the joints do not twist
	var kick := Vector2(away * HIT_KNOCKBACK.x, HIT_KNOCKBACK.y)
	for body in _rig:
		body.apply_central_impulse((kick - body.linear_velocity) * body.mass)

## End this life, blown up or lost off the level. The level restarts from died.
func kill(explode: bool) -> void:
	if _dead:
		return
	_dead = true
	modulate.a = 1.0
	cannon_move_player.stop()
	if explode:
		var fx: Node2D = EXPLOSION_SCENE.instantiate()
		fx.global_position = chassis.global_position
		fx.scale = Vector2.ONE * DEATH_EXPLOSION_SCALE
		get_tree().current_scene.add_child(fx)
		visible = false
		for body in _rig:
			body.set_deferred("freeze", true)
	died.emit()

func _update_damage(delta: float) -> void:
	_stun_left = maxf(_stun_left - delta, 0.0)
	_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)
	var blink_off := fmod(_invulnerable_left, BLINK_PERIOD * 2.0) > BLINK_PERIOD
	modulate.a = 0.25 if _invulnerable_left > 0.0 and blink_off else 1.0
	var enemy := hurtbox.touching_enemy()
	if enemy:
		take_hit(enemy.global_position)

func _is_grounded() -> bool:
	# Consider grounded only on near-upward normals and while not ascending fast
	for c in ground_casts:
		if c.is_colliding():
			var n: Vector2 = c.get_collision_normal()
			if n.dot(Vector2.UP) > GROUND_NORMAL_DOT_THRESHOLD and chassis.linear_velocity.y >= GROUNDED_ASCENT_MAX:
				return true
	return false

func _update_facing() -> void:
	var vel := chassis.linear_velocity
	
	# Always face right
	_facing = 1
	sprite.flip_h = false
	
	var grounded := _is_grounded()
	var anim := "idle"
	if not grounded and vel.y < -20.0:
		anim = "jump"
	elif abs(vel.x) > 12.0:
		anim = "move"
	
	if sprite.animation != anim:
		sprite.play(anim)
	# Keep antenna in sync, using "fall" when descending
	if antenna and antenna is AnimatedSprite2D:
		var ant_anim := anim
		if not grounded and vel.y > 20.0:
			ant_anim = "fall"
		var ant := antenna as AnimatedSprite2D
		if ant.animation != ant_anim:
			ant.play(ant_anim)

func _exit_tree() -> void:
	_in_tree = false
	if cannon_move_player:
		cannon_move_player.stop()
	if jump_player:
		jump_player.stop()
	if shoot_player:
		shoot_player.stop()
	if hurt_player:
		hurt_player.stop()
	if shoot_timer:
		shoot_timer.stop()

# --- Eye blink ---
func _start_blink_loop() -> void:
	while _in_tree and eye and eye is AnimatedSprite2D:
		var wait := _blink_rng.randf_range(2.0, 6.0)
		await get_tree().create_timer(wait).timeout
		if not _in_tree:
			break
		await _blink_once()
		if not _in_tree:
			break
		if _blink_rng.randf() < 0.15:
			await get_tree().create_timer(0.18).timeout
			if not _in_tree:
				break
			await _blink_once()

func _blink_once() -> void:
	if not _in_tree:
		return
	if not eye or not (eye is AnimatedSprite2D):
		return
	# Manually step frames: open -> half -> closed -> half -> open
	var e := eye as AnimatedSprite2D
	e.stop()
	for f in [0, 1, 2, 1, 0]:
		if not _in_tree:
			return
		e.frame = f
		await get_tree().create_timer(_blink_rng.randf_range(0.03, 0.07)).timeout
