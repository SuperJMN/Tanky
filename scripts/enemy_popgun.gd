extends Area2D
class_name EnemyPopgun

## Toy cork gun on a wooden block. When Tanky comes into range it turns its barrel and lobs
## corks that land where he is heading.

const CORK_SCENE := preload("res://scenes/cork.tscn")
const CORK_GRAVITY_SCALE := 0.8
# Flight time grows with distance up to MAX_FLIGHT_TIME, which keeps the arc low (~80 px):
# high lobs would land on the one-way tops of the background hills.
const CORK_SPEED_X := 450.0  # px/s
const MIN_FLIGHT_TIME := 0.45
const MAX_FLIGHT_TIME := 0.9
const TARGET_LEAD := 0.5  # fraction of Tanky's motion during the flight to aim ahead
const AIM_SPEED := 6.0
const RECOIL := 5.0

@export var hit_points := 3
@export var fire_range := 520.0
@export var fire_interval := 2.0

@onready var base: Sprite2D = $Base
@onready var barrel: Node2D = $Barrel
@onready var barrel_sprite: Sprite2D = $Barrel/Sprite2D
@onready var muzzle: Marker2D = $Barrel/Muzzle
@onready var pop_player: AudioStreamPlayer2D = $PopPlayer

var _reload := 1.0
var _barrel_sprite_x := 0.0

func _ready() -> void:
	add_to_group("enemies")
	_barrel_sprite_x = barrel_sprite.position.x

func _physics_process(delta: float) -> void:
	barrel_sprite.position.x = move_toward(barrel_sprite.position.x, _barrel_sprite_x, 30.0 * delta)
	var player := EnemyKit.player(self)
	if player == null:
		return
	var target := player.target_position()
	base.flip_h = target.x < global_position.x
	if absf(target.x - global_position.x) > fire_range:
		return
	var launch := _launch_velocity(muzzle.global_position, target, player.chassis.linear_velocity)
	barrel.rotation = lerp_angle(barrel.rotation, launch.angle(), AIM_SPEED * delta)
	barrel_sprite.flip_v = absf(wrapf(barrel.rotation, -PI, PI)) > PI / 2.0
	_reload -= delta
	if _reload <= 0.0:
		_fire(launch)
		_reload = fire_interval

# Velocity that lands a cork on the target, aiming partly ahead of where it is moving.
func _launch_velocity(from: Vector2, target: Vector2, target_velocity: Vector2) -> Vector2:
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	gravity *= CORK_GRAVITY_SCALE
	var flight_time := clampf(absf(target.x - from.x) / CORK_SPEED_X, MIN_FLIGHT_TIME, MAX_FLIGHT_TIME)
	var aim := target + Vector2(target_velocity.x, 0.0) * flight_time * TARGET_LEAD
	var to_aim := aim - from
	return Vector2(to_aim.x / flight_time, to_aim.y / flight_time - 0.5 * gravity * flight_time)

func _fire(launch: Vector2) -> void:
	var cork := CORK_SCENE.instantiate() as Projectile
	cork.gravity_scale = CORK_GRAVITY_SCALE
	cork.global_position = muzzle.global_position
	cork.velocity = launch
	cork.shooter = self
	get_tree().current_scene.add_child(cork)
	barrel_sprite.position.x = _barrel_sprite_x - RECOIL
	pop_player.pitch_scale = randf_range(1.5, 1.7)
	EnemyKit.play_sound(pop_player)

func hit_by_projectile(_projectile: Projectile) -> void:
	hit_points -= 1
	if hit_points <= 0:
		EnemyKit.explode(self)
	else:
		EnemyKit.flash(base)
		EnemyKit.flash(barrel_sprite)
