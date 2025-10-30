extends Node2D
class_name Explosion

@export var fps: float = 30.0

@onready var sprite: Sprite2D = $Sprite2D
var _acc: float = 0.0
var _frame_index: int = 0

func _ready() -> void:
	_frame_index = 0
	sprite.frame = 0

func _process(delta: float) -> void:
	_acc += delta
	var frame_time: float = 1.0 / max(fps, 1.0)
	var total_frames: int = max(1, sprite.hframes * sprite.vframes)
	while _acc >= frame_time:
		_acc -= frame_time
		_frame_index += 1
		if _frame_index >= total_frames:
			queue_free()
			return
		sprite.frame = _frame_index
