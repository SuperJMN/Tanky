extends Area2D
class_name Goal

## End-of-level flag. When Tanky touches it, it bursts into confetti and emits reached.

signal reached

const WAVE_FPS := 6.0
const CELEBRATE_WAVE_FPS := 16.0
const CONFETTI_BURSTS := 3
const CONFETTI_INTERVAL := 0.7  # s between bursts

@onready var flag: Sprite2D = $Flag
@onready var confetti: CPUParticles2D = $Confetti

var _reached := false
var _wave_t := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_wave_t += delta * (CELEBRATE_WAVE_FPS if _reached else WAVE_FPS)
	flag.frame = int(_wave_t) % flag.hframes

func _on_body_entered(body: Node) -> void:
	if _reached or not body.get_parent() is Tanky:
		return
	_reached = true
	reached.emit()
	for i in CONFETTI_BURSTS:
		confetti.restart()
		await get_tree().create_timer(CONFETTI_INTERVAL).timeout
