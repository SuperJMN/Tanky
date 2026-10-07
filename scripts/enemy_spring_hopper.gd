extends CharacterBody2D
class_name EnemySpringHopper

## Rubber head on a spring. It bounces in place until Tanky comes near, then hops after him.
## It squashes before every hop, so the player can read the timing.

enum Pose { SQUASH, IDLE, STRETCH }

const SQUASH_BEFORE_HOP := 0.25  # s of crouching before leaving the ground
const LAND_SQUASH := 0.12  # s of squash after landing

@export var hit_points := 2
@export var hop_speed := 560.0
@export var max_hop_run := 220.0  # px/s of horizontal speed at most
@export var idle_hop_speed := 260.0
@export var rest_time := 0.8
@export var sight_range := 520.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var boing_player: AudioStreamPlayer2D = $BoingPlayer

var _rest_left := 0.0
var _since_landing := 0.0
var _was_on_floor := true

func _ready() -> void:
	add_to_group("enemies")
	_rest_left = randf_range(0.2, rest_time)

func _physics_process(delta: float) -> void:
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	if is_on_floor():
		if not _was_on_floor:
			_since_landing = 0.0
			_rest_left = rest_time
		_since_landing += delta
		velocity.x = 0.0
		_rest_left -= delta
		if _rest_left <= 0.0:
			_hop()
	else:
		velocity.y += gravity * delta
	_was_on_floor = is_on_floor()
	move_and_slide()
	_update_pose()

func _hop() -> void:
	var player := EnemyKit.player(self)
	var to_player_x := INF
	if player:
		to_player_x = player.target_position().x - global_position.x
	if absf(to_player_x) > sight_range:
		velocity = Vector2(0.0, -idle_hop_speed)
	else:
		# Aim the landing at Tanky
		var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
		var air_time := 2.0 * hop_speed / gravity
		velocity = Vector2(clampf(to_player_x / air_time, -max_hop_run, max_hop_run), -hop_speed)
		sprite.flip_h = to_player_x < 0.0
	boing_player.pitch_scale = randf_range(1.6, 1.9)
	EnemyKit.play_sound(boing_player)

func _update_pose() -> void:
	var pose := Pose.IDLE
	if is_on_floor():
		if _rest_left < SQUASH_BEFORE_HOP or _since_landing < LAND_SQUASH:
			pose = Pose.SQUASH
	elif velocity.y < 0.0:
		pose = Pose.STRETCH
	sprite.frame = pose

func hit_by_projectile(_projectile: Projectile) -> void:
	hit_points -= 1
	if hit_points <= 0:
		EnemyKit.explode(self)
	else:
		EnemyKit.flash(sprite)
