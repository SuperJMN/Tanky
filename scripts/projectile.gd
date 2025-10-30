extends Area2D
class_name Projectile

@export var lifespan := 2.5
@export var gravity_scale := 1.0

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
	if body != shooter:
		queue_free()
