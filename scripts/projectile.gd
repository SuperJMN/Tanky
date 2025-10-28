extends Area2D
class_name Projectile

@export var speed: float = 420.0
@export var lifespan: float = 2.0
var direction: int = 1
var shooter: Node = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var timer: Timer = $Timer

func _ready() -> void:
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)
	timer.wait_time = lifespan
	timer.timeout.connect(queue_free)
	timer.start()
	_update_orientation()

func _physics_process(delta: float) -> void:
	global_position.x += speed * direction * delta

func _on_hit(_body: Node) -> void:
	if _body == shooter:
		return
	queue_free()

func _update_orientation() -> void:
	if sprite:
		sprite.flip_h = direction < 0

func set_direction(value: int) -> void:
	direction = 1 if value >= 0 else -1
	_update_orientation()

func set_shooter(value: Node) -> void:
	shooter = value
