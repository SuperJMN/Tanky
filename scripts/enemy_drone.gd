extends Area2D
class_name EnemyDrone

## Propeller drone: it patrols back and forth while hovering. With a bomb cooldown it also drops
## bombs, released early enough to land where Tanky is heading.

const BOMB_SCENE := preload("res://scenes/bomb.tscn")
const PROPELLER_FPS := 18.0
const BOMB_GRAVITY_SCALE := 0.7  # bombs fall slower than real ones, so they can be dodged
const BOMB_AIM_TOLERANCE := 28.0  # px between the predicted landing spot and Tanky

@export var patrol_distance := 220.0
@export var patrol_speed := 80.0
@export var hover_amplitude := 18.0
@export var hover_frequency := 1.4
@export var hover_damp := 6.0
@export var hit_points := 1
## Seconds between bombs; 0 means this drone never bombs.
@export var bomb_cooldown := 0.0

@onready var sprite: Sprite2D = $Sprite2D

var _start_position := Vector2.ZERO
var _direction := 1.0
var _hover_t := 0.0
var _spin_t := 0.0
var _bomb_wait := 0.0

func _ready() -> void:
	_start_position = global_position
	add_to_group("enemies")
	_face_direction()

func _physics_process(delta: float) -> void:
	_hover_t += delta * hover_frequency
	var desired_y := _start_position.y + sin(_hover_t) * hover_amplitude
	var dy := desired_y - global_position.y
	var velocity_y := dy * hover_damp
	var velocity_x := patrol_speed * _direction
	global_position += Vector2(velocity_x, velocity_y) * delta
	var offset_x := global_position.x - _start_position.x
	if absf(offset_x) >= patrol_distance:
		_direction *= -1.0
		offset_x = clampf(offset_x, -patrol_distance, patrol_distance)
		global_position.x = _start_position.x + offset_x
		_face_direction()
	_spin_t += delta * PROPELLER_FPS
	sprite.frame = int(_spin_t) % sprite.hframes
	_update_bombing(delta, velocity_x)

# The art faces right.
func _face_direction() -> void:
	if sprite:
		sprite.flip_h = _direction < 0.0

func _update_bombing(delta: float, velocity_x: float) -> void:
	if bomb_cooldown <= 0.0:
		return
	_bomb_wait -= delta
	var player := EnemyKit.player(self)
	if _bomb_wait > 0.0 or player == null:
		return
	var target := player.target_position()
	var drop := target.y - global_position.y
	if drop < 40.0:
		return
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	var fall_time := sqrt(2.0 * drop / (gravity * BOMB_GRAVITY_SCALE))
	var landing_x := global_position.x + velocity_x * fall_time
	var player_x := target.x + player.chassis.linear_velocity.x * fall_time
	if absf(landing_x - player_x) > BOMB_AIM_TOLERANCE:
		return
	var bomb := BOMB_SCENE.instantiate() as Projectile
	bomb.gravity_scale = BOMB_GRAVITY_SCALE
	bomb.global_position = global_position + Vector2(0.0, 18.0)
	bomb.velocity = Vector2(velocity_x, 0.0)
	bomb.shooter = self
	get_tree().current_scene.add_child(bomb)
	_bomb_wait = bomb_cooldown

func hit_by_projectile(_projectile: Projectile) -> bool:
	hit_points -= 1
	if hit_points <= 0:
		EnemyKit.explode(self)
		return true
	else:
		EnemyKit.flash(sprite)
	return false
