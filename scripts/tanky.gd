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

@onready var chassis: RigidBody2D = $RigidBody2D
@onready var front_wheel: RigidBody2D = $FrontWheel
@onready var rear_wheel: RigidBody2D = $RearWheel
@onready var sprite: AnimatedSprite2D = $RigidBody2D/AnimatedSprite2D
@onready var gun: Node2D = $RigidBody2D/Cannon
@onready var muzzle: Marker2D = $RigidBody2D/Cannon/Muzzle
@onready var jump_player: AudioStreamPlayer2D = $RigidBody2D/JumpPlayer
@onready var shoot_player: AudioStreamPlayer2D = $RigidBody2D/ShootPlayer
@onready var ground_casts: Array[RayCast2D] = [$RigidBody2D/GroundCastFront, $RigidBody2D/GroundCastRear]
@onready var camera: Camera2D = $Camera2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var head_rig: Node2D = $RigidBody2D/Node2D

var _facing := 1
var _accel_time := 0.0
var _last_move_dir := 0.0
var _head_bob_t := 0.0
var _head_rig_base_y := 0.0

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

func _physics_process(delta: float) -> void:
	var move := Input.get_axis("move_left", "move_right")
	var grounded := ground_casts.any(func(c): return c.is_colliding())
	
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
func _shoot() -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	projectile.global_position = muzzle.global_position
	var aim_dir: Vector2 = muzzle.global_transform.x.normalized()
	projectile.velocity = aim_dir * PROJECTILE_SPEED + chassis.linear_velocity * PROJECTILE_INHERIT_VEL
	projectile.shooter = chassis
	get_tree().current_scene.add_child(projectile)
	shoot_player.play()
	shoot_timer.start()


func _update_facing() -> void:
	var vel := chassis.linear_velocity
	
	# Always face right
	_facing = 1
	sprite.flip_h = false
	
	var grounded := ground_casts.any(func(c): return c.is_colliding())
	var anim := "idle"
	if not grounded and vel.y < -20.0:
		anim = "jump"
	elif abs(vel.x) > 12.0:
		anim = "move"
	
	if sprite.animation != anim:
		sprite.play(anim)
