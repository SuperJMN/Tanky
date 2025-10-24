extends Node2D

# Signals
signal enemy_defeated(enemy_type: String, killer: Node2D)

# Scene references
@onready var tanky = $Tanky
@onready var ui = $UI

# Enemy spawning
var ship_scene = preload("res://scenes/enemies/ship.tscn")
var spawn_timer: Timer

# Score tracking
var score: int = 0
var score_table = {
	"Ship": 100,
	"Bomb": 20
}

func _ready():
	# Setup enemy spawner
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 2.5
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()
	
	# Connect signals
	enemy_defeated.connect(_on_enemy_defeated)

func _on_spawn_timer_timeout():
	spawn_ship()

func spawn_ship():
	var ship = ship_scene.instantiate()
	ship.position = Vector2(get_viewport_rect().size.x, randf_range(50, 200))
	ship.defeated.connect(_on_ship_defeated)
	add_child(ship)

func _on_ship_defeated(killer: Node2D):
	enemy_defeated.emit("Ship", killer)

func _on_enemy_defeated(enemy_type: String, killer: Node2D):
	if killer == tanky:
		score += score_table.get(enemy_type, 0)
		ui.update_score(score)

func get_stage_bounds() -> Rect2:
	return get_viewport_rect()
