extends Node2D

const PALMTREE_TEXTURES := [
	preload("res://sprites/palmtree2.png"),
	preload("res://sprites/palmtree3.png")
]
const FALL_MARGIN := 160.0  # px below the area's bottom edge where a fall ends the life
const RESTART_DELAY := 2.0  # s between losing a life and restarting the level

@export_node_path("Node2D") var palm_container_path: NodePath
@export_node_path("AudioStreamPlayer") var music_path: NodePath
@export_node_path("Node2D") var tanky_path: NodePath
@export_node_path("CanvasLayer") var hud_path: NodePath
@export_node_path("Area2D") var goal_path: NodePath
@export_node_path("Node2D") var enemies_path: NodePath
@export_node_path("AudioStreamPlayer") var fanfare_path: NodePath
@export_node_path("Node2D") var start_stage_path: NodePath
@export_node_path("ColorRect") var sky_path: NodePath
@export_node_path("AudioStreamPlayer") var door_sound_path: NodePath
@onready var palm_container: Node2D = get_node(palm_container_path)
@onready var music: AudioStreamPlayer = get_node(music_path)
@onready var tanky: Tanky = get_node(tanky_path)
@onready var hud: Hud = get_node(hud_path)
@onready var goal: Goal = get_node(goal_path)
@onready var enemies: Node2D = get_node(enemies_path)
@onready var fanfare: AudioStreamPlayer = get_node(fanfare_path)
@onready var start_stage: Stage = get_node(start_stage_path)
@onready var sky: ColorRect = get_node(sky_path)
@onready var door_sound: AudioStreamPlayer = get_node(door_sound_path)

var _fall_limit := INF
var _waiting_restart := false
var _traveling := false

func _ready() -> void:
	_enter_stage(start_stage)
	for door: Door in get_tree().get_nodes_in_group("doors"):
		door.entered.connect(_on_door_entered)
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

# Frame the camera, the sky and the fall limit to the area Tanky is in.
func _enter_stage(stage: Stage) -> void:
	sky.color = stage.sky_color
	var bounds := stage.bounds()
	if bounds.has_area():
		tanky.set_camera_limits(bounds, stage.has_ceiling)
		_fall_limit = bounds.end.y + FALL_MARGIN

# A door fades the screen out, moves Tanky to its exit in another area and fades back in.
func _on_door_entered(door: Door) -> void:
	if _traveling or not tanky.is_alive():
		return
	_traveling = true
	tanky.set_traveling(true)
	door_sound.play()
	await hud.fade_screen(true)
	_enter_stage(_stage_at(door.exit.global_position))
	tanky.teleport(door.exit.global_position)
	await hud.fade_screen(false)
	tanky.set_traveling(false)
	_traveling = false

func _stage_at(point: Vector2) -> Stage:
	for stage: Stage in get_tree().get_nodes_in_group("stages"):
		if stage.bounds().has_point(point):
			return stage
	push_error("no stage contains %s" % point)
	return start_stage

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
	if door_sound:
		door_sound.stop()

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
