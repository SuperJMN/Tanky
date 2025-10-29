extends Node2D
class_name Tanky

const PIXELS_PER_METER := 100.0
const BODY_LENGTH_METERS := 0.5
const TOP_SPEED_BODY_LENGTHS := 3.0
const MAX_SPEED := TOP_SPEED_BODY_LENGTHS * BODY_LENGTH_METERS * PIXELS_PER_METER
const DRIVE_TORQUE := 50000.0
const BRAKE_TORQUE := 10000.0
const AIR_CONTROL_FACTOR := 0.55
const DRIVE_FORCE_GAIN := 650.0
const JUMP_HEIGHT_METERS := 1.5
const SHOOT_COOLDOWN := 0.35
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const SPRITESHEET_PATH := "res://sprites/tanky_spritesheet.png"

@onready var chassis: RigidBody2D = $Chassis
@onready var front_wheel: RigidBody2D = $FrontWheel
@onready var rear_wheel: RigidBody2D = $RearWheel
@onready var sprite: AnimatedSprite2D = $Chassis/AnimatedSprite2D
@onready var muzzle: Marker2D = $Chassis/Muzzle
@onready var jump_player: AudioStreamPlayer2D = $Chassis/JumpPlayer
@onready var shoot_player: AudioStreamPlayer2D = $Chassis/ShootPlayer
@onready var front_cast: RayCast2D = $Chassis/GroundCastFront
@onready var rear_cast: RayCast2D = $Chassis/GroundCastRear
@onready var camera: Camera2D = $Camera2D

var _shoot_cooldown := 0.0
var _facing_direction := 1
var _jump_impulse := 0.0
var _muzzle_default_offset := 0.0

func _ready() -> void:
	_update_jump_impulse()
	_ensure_sprite_frames()
	front_cast.enabled = true
	rear_cast.enabled = true
	_muzzle_default_offset = muzzle.position.x
	if sprite.sprite_frames:
		sprite.play("idle")
	if camera:
		camera.make_current()
		camera.global_position = chassis.global_position

func _physics_process(delta: float) -> void:
	var move_input := Input.get_axis("move_left", "move_right")
	var grounded := _is_grounded()
	_apply_drive(move_input, grounded)
	_apply_drag(move_input, grounded)

	if Input.is_action_just_pressed("jump") and grounded:
		chassis.apply_central_impulse(Vector2(0, -_jump_impulse))
		jump_player.play()

	_handle_shoot(delta)
	_update_orientation()
	_update_camera()

func _update_jump_impulse() -> void:
	var gravity := float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
	var height_pixels := JUMP_HEIGHT_METERS * PIXELS_PER_METER
	var jump_velocity := sqrt(2.0 * gravity * height_pixels)
	_jump_impulse = chassis.mass * jump_velocity

func _apply_drive(move_input: float, grounded: bool) -> void:
	if move_input == 0.0:
		return

	var torque_factor := DRIVE_TORQUE
	if not grounded:
		torque_factor *= AIR_CONTROL_FACTOR

	var velocity := chassis.linear_velocity.x
	if abs(velocity) > MAX_SPEED and sign(velocity) == sign(move_input):
		return

	var torque := torque_factor * move_input
	front_wheel.apply_torque(torque)
	rear_wheel.apply_torque(torque)

func _apply_drag(move_input: float, grounded: bool) -> void:
	var target_speed := move_input * MAX_SPEED
	var speed := chassis.linear_velocity.x
	var drag_strength := (target_speed - speed) * DRIVE_FORCE_GAIN
	var drag_factor := 1.0 if grounded else AIR_CONTROL_FACTOR
	chassis.apply_central_force(Vector2(drag_strength * drag_factor, 0.0))

	if move_input == 0.0:
		var brake_front := -front_wheel.angular_velocity * BRAKE_TORQUE
		var brake_rear := -rear_wheel.angular_velocity * BRAKE_TORQUE
		front_wheel.apply_torque(brake_front)
		rear_wheel.apply_torque(brake_rear)

func _handle_shoot(delta: float) -> void:
	if _shoot_cooldown > 0.0:
		_shoot_cooldown -= delta

	if Input.is_action_pressed("shoot") and _shoot_cooldown <= 0.0:
		var projectile := PROJECTILE_SCENE.instantiate()
		projectile.global_position = muzzle.global_position
		if projectile.has_method("set_direction"):
			projectile.set_direction(_facing_direction)
		if projectile.has_method("set_shooter"):
			projectile.set_shooter(chassis)
		get_tree().current_scene.add_child(projectile)
		shoot_player.play()
		_shoot_cooldown = SHOOT_COOLDOWN

func _is_grounded() -> bool:
	return front_cast.is_colliding() or rear_cast.is_colliding()

func _update_orientation() -> void:
	var horizontal_velocity := chassis.linear_velocity.x
	var input_dir := Input.get_axis("move_left", "move_right")

	if abs(horizontal_velocity) > 2.0:
		_facing_direction = sign(horizontal_velocity)
	elif input_dir != 0.0:
		_facing_direction = sign(input_dir)

	sprite.flip_h = _facing_direction < 0
	muzzle.position.x = _muzzle_default_offset * _facing_direction

	if not _is_grounded() and chassis.linear_velocity.y < -20.0:
		_play_animation("jump")
	elif abs(horizontal_velocity) > 12.0:
		_play_animation("move")
	else:
		_play_animation("idle")

func _ensure_sprite_frames() -> void:
	if sprite.sprite_frames and sprite.sprite_frames.get_animation_names().size() > 0:
		return

	var sheet := load(SPRITESHEET_PATH)
	if sheet == null:
		return

	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_animation("move")
	frames.add_animation("jump")
	frames.set_animation_speed("idle", 2.0)
	frames.set_animation_speed("move", 10.0)
	frames.set_animation_loop("idle", true)
	frames.set_animation_loop("move", true)
	frames.set_animation_loop("jump", false)

	var frame_size := Vector2(32, 32)
	var frame_count := int(sheet.get_width() / frame_size.x)
	for index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(Vector2(index * frame_size.x, 0), frame_size)
		frames.add_frame("move", atlas)
		if index == 0:
			frames.add_frame("idle", atlas)

	if frames.get_frame_count("move") > 0:
		frames.add_frame("jump", frames.get_frame_texture("move", 0))

	sprite.sprite_frames = frames
	sprite.animation = "idle"
	sprite.play()

func _play_animation(name: String) -> void:
	if sprite.animation == name:
		return
	sprite.play(name)

func _update_camera() -> void:
	if camera:
		camera.global_position = chassis.global_position
		camera.rotation = 0.0
