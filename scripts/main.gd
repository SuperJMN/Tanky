extends Node2D

const PALMTREE_TEXTURES := [
	preload("res://sprites/palmtree2.png"),
	preload("res://sprites/palmtree3.png")
]

@export_node_path("Node2D") var palm_container_path: NodePath
@export_node_path("AudioStreamPlayer") var music_path: NodePath
@onready var palm_container: Node2D = get_node(palm_container_path)
@onready var music: AudioStreamPlayer = get_node(music_path)

func _ready() -> void:
	if _is_headless():
		if music:
			music.stop()
			music.stream = null
		return
	music.stream = load("res://sounds/ladynavigation.mp3")
	music.play()
	_spawn_palm_trees()

func _is_headless() -> bool:
	return OS.has_feature("headless") or (Engine.has_singleton("DisplayServer") and DisplayServer.get_name() == "headless")

func _exit_tree() -> void:
	if music:
		music.stop()
		# Liberar el recurso para evitar que quede "in use" al salir
		music.stream = null

func _spawn_palm_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(60):
		var sprite := Sprite2D.new()
		sprite.texture = PALMTREE_TEXTURES[rng.randi_range(0, PALMTREE_TEXTURES.size() - 1)]
		sprite.position = Vector2(
			i * 90 + rng.randf_range(-60, 60),
			rng.randf_range(-250, -100)
		)
		sprite.scale = Vector2(rng.randf_range(0.8, 1.5), rng.randf_range(0.8, 1.5))
		palm_container.add_child(sprite)
