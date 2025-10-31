extends Area2D
class_name Projectile

const EXPLOSION_SCENE := preload("res://scenes/explosion.tscn")
const EXPLOSION_SOUND := preload("res://sounds/explosion.wav")

@export var lifespan := 2.5
@export var gravity_scale := 1.0
@export var explosion_volume_db: float = 6.0
@export var explosion_pitch_min: float = 0.92
@export var explosion_pitch_max: float = 1.08

var velocity: Vector2 = Vector2.ZERO
var shooter: Node

func _ready() -> void:
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)
	get_tree().create_timer(lifespan).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	velocity.y += gravity * gravity_scale * delta
	global_position += velocity * delta
	if velocity.length() > 0.01:
		rotation = velocity.angle()

func _on_hit(body: Node) -> void:
	if body == shooter:
		return
	# Ignore one-way platforms when approaching from below (bullet going up)
	if body is TileMapLayer and velocity.y < 0.0:
		return
	_spawn_explosion()
	queue_free()

func _spawn_explosion() -> void:
	var explosion := EXPLOSION_SCENE.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	# Play explosion SFX at impact point on SFX bus as a detached one-shot
	var sfx := AudioStreamPlayer2D.new()
	sfx.bus = "SFX"
	sfx.stream = EXPLOSION_SOUND
	sfx.global_position = global_position
	sfx.volume_db = explosion_volume_db
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	sfx.pitch_scale = rng.randf_range(explosion_pitch_min, explosion_pitch_max)
	get_tree().current_scene.add_child(sfx)
	sfx.play()
	sfx.finished.connect(Callable(sfx, "queue_free"))
