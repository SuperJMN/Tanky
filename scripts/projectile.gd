extends Area2D
class_name Projectile

@export var speed := 420.0
@export var lifespan := 2.0

var direction := 1:
	set(value):
		direction = 1 if value >= 0 else -1
		$Sprite2D.flip_h = direction < 0

var shooter: Node

func _ready() -> void:
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)
	get_tree().create_timer(lifespan).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position.x += speed * direction * delta

func _on_hit(body: Node) -> void:
	if body != shooter:
		queue_free()
