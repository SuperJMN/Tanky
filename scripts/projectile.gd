extends Area2D
class_name Projectile

@export var lifespan := 2.5
@export var gravity_scale := 1.0
## Effect spawned where the projectile hits; none when empty.
@export var impact_scene: PackedScene = preload("res://scenes/explosion.tscn")
## Turn the projectile to point along its flight path.
@export var face_velocity := true

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
	if face_velocity and velocity.length() > 0.01:
		rotation = velocity.angle()

func _on_hit(body: Node) -> void:
	# Two overlaps in the same frame must not hit twice
	if body == shooter or is_queued_for_deletion():
		return
	# Ignore one-way platforms when approaching from below (bullet going up)
	if body is TileMapLayer and velocity.y < 0.0:
		return
	if body.has_method("hit_by_projectile"):
		body.hit_by_projectile(self)
	_spawn_impact()
	queue_free()

func _spawn_impact() -> void:
	if impact_scene == null:
		return
	var impact: Node2D = impact_scene.instantiate()
	impact.global_position = global_position
	get_tree().current_scene.add_child(impact)
