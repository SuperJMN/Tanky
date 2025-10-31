extends Node2D
class_name Tanky

const PIXELS_PER_METER := 100.0
const BODY_LENGTH := 50.0  # 0.5m * 100px/m
const MIN_SPEED := 150.0  # 3 body-lengths/sec
const MAX_SPEED := 250.0  # 5 body-lengths/sec
const ACCEL_TIME := 1.5  # seconds to reach max speed
const DRIVE_TORQUE := 50000.0
const BRAKE_TORQUE := 10000.0
const AIR_CONTROL := 0.35
const DRIVE_FORCE := 650.0
const JUMP_HEIGHT := 150.0  # 1.5m in pixels
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const PROJECTILE_SPEED := 700.0
const PROJECTILE_INHERIT_VEL := 0.25
const GUN_MIN_DEG := -60.0
const GUN_MAX_DEG := 10.0
const GUN_AIM_SPEED_DEG := 90.0

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

var _facing := 1
var _accel_time := 0.0
var _last_move_dir := 0.0
var _head_bob_t := 0.0
var _head_rig_base_y := 0.0
var _blink_rng := RandomNumberGenerator.new()
var _alive := true

func _ready() -> void:

	sprite.play("idle")
	camera.make_current()
	
	# Cache head rig base position
	if head_rig:
		_head_rig_base_y = head_rig.position.y
	
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

func _physics_process(delta: float) -> void:
	var move := Input.get_axis("move_left", "move_right")
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
	
	if Input.is_action_just_pressed("jump") and grounded:
		var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
		chassis.apply_central_impulse(Vector2.UP * chassis.mass * sqrt(2.0 * gravity * JUMP_HEIGHT))
		jump_player.play()
	
	if Input.is_action_pressed("shoot") and shoot_timer.is_stopped():
		_shoot()
	
	_update_facing()
	camera.global_position = chassis.global_position


func _update_acceleration(move: float, delta: float) -> void:
	if move != 0.0 and sign(move) == sign(_last_move_dir):
		_accel_time = min(_accel_time + delta, ACCEL_TIME)
	else:
		_accel_time = 0.0
	_last_move_dir = move
	
	var current_max: float = lerp(MIN_SPEED, MAX_SPEED, _accel_time / ACCEL_TIME)

func _apply_drive(move: float, grounded: bool) -> void:
	if move == 0.0:
		return
	
	var current_max: float = lerp(MIN_SPEED, MAX_SPEED, _accel_time / ACCEL_TIME)
	var velocity := chassis.linear_velocity.x
	if abs(velocity) > current_max and sign(velocity) == sign(move):
		return
	
	var torque := DRIVE_TORQUE * move * (AIR_CONTROL if not grounded else 1.0)
	front_wheel.apply_torque(torque)
	rear_wheel.apply_torque(torque)

func _apply_drag(move: float, grounded: bool) -> void:
	var current_max: float = lerp(MIN_SPEED, MAX_SPEED, _accel_time / ACCEL_TIME)
	var drag: float = (move * current_max - chassis.linear_velocity.x) * DRIVE_FORCE * (1.0 if grounded else AIR_CONTROL)
	chassis.apply_central_force(Vector2(drag, 0.0))
	
	if move == 0.0:
		for wheel in [front_wheel, rear_wheel]:
			wheel.apply_torque(-wheel.angular_velocity * BRAKE_TORQUE)

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
	_alive = false
	if cannon_move_player:
		cannon_move_player.stop()
	if jump_player:
		jump_player.stop()
	if shoot_player:
		shoot_player.stop()
	if shoot_timer:
		shoot_timer.stop()

# --- Eye blink ---
func _start_blink_loop() -> void:
	while _alive and eye and eye is AnimatedSprite2D:
		var wait := _blink_rng.randf_range(2.0, 6.0)
		await get_tree().create_timer(wait).timeout
		if not _alive:
			break
		await _blink_once()
		if not _alive:
			break
		if _blink_rng.randf() < 0.15:
			await get_tree().create_timer(0.18).timeout
			if not _alive:
				break
			await _blink_once()

func _blink_once() -> void:
	if not _alive:
		return
	if not eye or not (eye is AnimatedSprite2D):
		return
	# Manually step frames: open -> half -> closed -> half -> open
	var e := eye as AnimatedSprite2D
	e.stop()
	for f in [0, 1, 2, 1, 0]:
		if not _alive:
			return
		e.frame = f
		await get_tree().create_timer(_blink_rng.randf_range(0.03, 0.07)).timeout
