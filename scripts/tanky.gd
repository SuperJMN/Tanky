extends Node2D
class_name Tanky

const PIXELS_PER_METER := 100.0
const BODY_LENGTH := 50.0  # 0.5m * 100px/m
const MIN_SPEED := 150.0  # 3 body-lengths/sec
const MAX_SPEED := 250.0  # 5 body-lengths/sec
const ACCEL_TIME := 1.5  # seconds to reach max speed
const DRIVE_TORQUE := 50000.0
const BRAKE_TORQUE := 10000.0
const AIR_CONTROL := 0.55
const DRIVE_FORCE := 650.0
const JUMP_HEIGHT := 150.0  # 1.5m in pixels
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")

@onready var chassis: RigidBody2D = $Chassis
@onready var front_wheel: RigidBody2D = $FrontWheel
@onready var rear_wheel: RigidBody2D = $RearWheel
@onready var sprite: AnimatedSprite2D = $Chassis/AnimatedSprite2D
@onready var muzzle: Marker2D = $Chassis/Muzzle
@onready var jump_player: AudioStreamPlayer2D = $Chassis/JumpPlayer
@onready var shoot_player: AudioStreamPlayer2D = $Chassis/ShootPlayer
@onready var ground_casts: Array[RayCast2D] = [$Chassis/GroundCastFront, $Chassis/GroundCastRear]
@onready var camera: Camera2D = $Camera2D
@onready var shoot_timer: Timer = $ShootTimer

var _facing := 1
var _muzzle_offset := 0.0
var _accel_time := 0.0
var _last_move_dir := 0.0

func _ready() -> void:
	_muzzle_offset = muzzle.position.x
	sprite.play("idle")
	camera.make_current()

func _physics_process(delta: float) -> void:
	var move := Input.get_axis("move_left", "move_right")
	var grounded := ground_casts.any(func(c): return c.is_colliding())
	
	_update_acceleration(move, delta)
	_apply_drive(move, grounded)
	_apply_drag(move, grounded)
	
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

func _shoot() -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	projectile.global_position = muzzle.global_position
	projectile.direction = _facing
	projectile.shooter = chassis
	get_tree().current_scene.add_child(projectile)
	shoot_player.play()
	shoot_timer.start()


func _update_facing() -> void:
	var vel := chassis.linear_velocity
	var input := Input.get_axis("move_left", "move_right")
	
	if abs(vel.x) > 2.0:
		_facing = sign(vel.x)
	elif input != 0.0:
		_facing = sign(input)
	
	sprite.flip_h = _facing < 0
	muzzle.position.x = _muzzle_offset * _facing
	
	var grounded := ground_casts.any(func(c): return c.is_colliding())
	var anim := "idle"
	if not grounded and vel.y < -20.0:
		anim = "jump"
	elif abs(vel.x) > 12.0:
		anim = "move"
	
	if sprite.animation != anim:
		sprite.play(anim)
