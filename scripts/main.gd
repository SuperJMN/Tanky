extends Node2D

const PALMTREE_TEXTURES := [
	preload("res://sprites/palmtree2.png"),
	preload("res://sprites/palmtree3.png")
]
const FALL_MARGIN := 160.0  # px below the level's bottom edge where a fall ends the life
const RESTART_DELAY := 2.0  # s between losing a life and restarting the level

@export_node_path("Node2D") var palm_container_path: NodePath
@export_node_path("AudioStreamPlayer") var music_path: NodePath
@export_node_path("Node2D") var world_path: NodePath
@export_node_path("Node2D") var tanky_path: NodePath
@export_node_path("CanvasLayer") var hud_path: NodePath
@export_node_path("Area2D") var goal_path: NodePath
@export_node_path("Node2D") var enemies_path: NodePath
@export_node_path("AudioStreamPlayer") var fanfare_path: NodePath
@onready var palm_container: Node2D = get_node(palm_container_path)
@onready var music: AudioStreamPlayer = get_node(music_path)
@onready var world: Node2D = get_node(world_path)
@onready var tanky: Tanky = get_node(tanky_path)
@onready var hud: Hud = get_node(hud_path)
@onready var goal: Goal = get_node(goal_path)
@onready var enemies: Node2D = get_node(enemies_path)
@onready var fanfare: AudioStreamPlayer = get_node(fanfare_path)

var _fall_limit := INF
var _waiting_restart := false

func _ready() -> void:
	var bounds := _level_bounds()
	if bounds.has_area():
		tanky.set_camera_limits(bounds)
		_fall_limit = bounds.end.y + FALL_MARGIN
	hud.show_health(tanky.health, Tanky.MAX_HEALTH)
	tanky.health_changed.connect(hud.show_health)
	tanky.died.connect(_on_tanky_died)
	goal.reached.connect(_on_goal_reached)
	if _is_headless():
		if music:
			music.stop()
			music.stream = null
		return
	music.stream = load("res://sounds/ladynavigation.mp3")
	music.play()
	_spawn_palm_trees()

# World-space rectangle covered by every terrain layer in the level.
func _level_bounds() -> Rect2:
	var bounds := Rect2()
	var has_bounds := false
	for node in world.find_children("*", "TileMapLayer", true, false):
		var layer := node as TileMapLayer
		var used := layer.get_used_rect()
		if layer.tile_set == null or not used.has_area():
			continue
		var tile_size := Vector2(layer.tile_set.tile_size)
		var local := Rect2(Vector2(used.position) * tile_size, Vector2(used.size) * tile_size)
		var layer_bounds := layer.global_transform * local
		bounds = bounds.merge(layer_bounds) if has_bounds else layer_bounds
		has_bounds = true
	return bounds

func _physics_process(_delta: float) -> void:
	if tanky.is_alive() and tanky.chassis.global_position.y > _fall_limit:
		tanky.kill(false)

func _process(_delta: float) -> void:
	if _waiting_restart and Input.is_action_just_pressed("jump"):
		get_tree().reload_current_scene()

# Fanfare and celebration; once the fanfare ends, jump plays the level again.
func _on_goal_reached() -> void:
	if not tanky.is_alive():
		return
	music.stop()
	fanfare.play()
	tanky.celebrate()
	# The enemies freeze in place while Tanky celebrates
	enemies.process_mode = Node.PROCESS_MODE_DISABLED
	hud.show_stage_clear()
	await get_tree().create_timer(fanfare.stream.get_length()).timeout
	hud.show_restart_hint()
	_waiting_restart = true

# Losing a life sends Tanky back to the start: the whole level, enemies included, restarts.
func _on_tanky_died() -> void:
	music.stop()
	await get_tree().create_timer(RESTART_DELAY).timeout
	get_tree().reload_current_scene()

func _is_headless() -> bool:
	return OS.has_feature("headless") or (Engine.has_singleton("DisplayServer") and DisplayServer.get_name() == "headless")

func _exit_tree() -> void:
	if music:
		music.stop()
		# Liberar el recurso para evitar que quede "in use" al salir
		music.stream = null
	if fanfare:
		fanfare.stop()
		fanfare.stream = null

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
