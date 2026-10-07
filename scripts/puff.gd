extends CPUParticles2D
class_name Puff

## One-shot dust puff for small impacts. It frees itself when its particles are gone.

func _ready() -> void:
	emitting = true
	finished.connect(queue_free)
