extends Node2D
class_name Explosion

@export var fps: float = 30.0
@export var sfx_volume_db: float = 6.0
@export var pitch_min: float = 0.92
@export var pitch_max: float = 1.08

@export_node_path("Sprite2D") var sprite_path: NodePath
@export_node_path("AudioStreamPlayer2D") var sfx_path: NodePath
@onready var sprite: Sprite2D = get_node(sprite_path)
@onready var sfx: AudioStreamPlayer2D = get_node(sfx_path)
var _acc: float = 0.0
var _frame_index: int = 0
var _anim_finished: bool = false

func _ready() -> void:
	_frame_index = 0
	sprite.frame = 0
	# Configure and play SFX
	sfx.volume_db = sfx_volume_db
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	sfx.pitch_scale = rng.randf_range(pitch_min, pitch_max)
	sfx.play()
	sfx.finished.connect(_on_sfx_finished)

func _process(delta: float) -> void:
	_acc += delta
	var frame_time: float = 1.0 / max(fps, 1.0)
	var total_frames: int = max(1, sprite.hframes * sprite.vframes)
	while _acc >= frame_time and not _anim_finished:
		_acc -= frame_time
		_frame_index += 1
		if _frame_index >= total_frames:
			_anim_finished = true
			sprite.visible = false
			break
		sprite.frame = _frame_index
	# If animation finished and SFX not playing, free
	if _anim_finished and not sfx.playing:
		queue_free()

func _on_sfx_finished() -> void:
	if _anim_finished:
		queue_free()
