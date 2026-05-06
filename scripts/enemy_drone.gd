extends Area2D
class_name EnemyDrone

const EXPLOSION_SCENE := preload("res://scenes/explosion.tscn")

@export var patrol_distance := 220.0
@export var patrol_speed := 80.0
@export var hover_amplitude := 18.0
@export var hover_frequency := 1.4
@export var hover_damp := 6.0
@export var hit_points := 1

@onready var sprite: Sprite2D = $Sprite2D

var _start_position := Vector2.ZERO
var _direction := 1.0
var _hover_t := 0.0

func _ready() -> void:
	_start_position = global_position
	add_to_group("enemies")

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
		if sprite:
			var scale := sprite.scale
			scale.x = signf(_direction) * absf(scale.x)
			sprite.scale = scale

func hit_by_projectile(projectile: Projectile) -> void:
	if hit_points <= 0:
		return
	hit_points -= 1
	if hit_points <= 0:
		_spawn_explosion()
		queue_free()

func _spawn_explosion() -> void:
	var fx := EXPLOSION_SCENE.instantiate()
	fx.global_position = global_position
	get_tree().current_scene.add_child(fx)
