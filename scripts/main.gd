extends Node2D

const PALMTREE_TEXTURES := [
	preload("res://sprites/palmtree2.png"),
	preload("res://sprites/palmtree3.png")
]

@onready var palm_container: Node2D = $ParallaxBackground/PalmTrees/PalmContainer

func _ready() -> void:
	$Music.play()
	_spawn_palm_trees()

func _spawn_palm_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(20):
		var sprite := Sprite2D.new()
		sprite.texture = PALMTREE_TEXTURES[rng.randi_range(0, PALMTREE_TEXTURES.size() - 1)]
		sprite.position = Vector2(
			i * 150 + rng.randf_range(-50, 50),
			rng.randf_range(-250, -100)
		)
		sprite.scale = Vector2(rng.randf_range(0.8, 1.5), rng.randf_range(0.8, 1.5))
		palm_container.add_child(sprite)
