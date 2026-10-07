extends CharacterBody2D
class_name EnemyWindupMouse

## Clockwork mouse. It trots along the ground and turns at walls and ledges. When it spots Tanky
## it stops, winds its key up and dashes at him.

enum State { WALK, WIND_UP, DASH }

const KEY_FPS := {State.WALK: 6.0, State.WIND_UP: 28.0, State.DASH: 14.0}
const FEET_STEP := 14.0  # px travelled per walking frame
const SIGHT_HEIGHT := 70.0  # Tanky must be roughly at the same height to be spotted

@export var hit_points := 2
@export var walk_speed := 55.0
@export var dash_speed := 280.0
@export var wind_up_time := 0.6
@export var dash_time := 1.1
@export var dash_rest := 1.5
@export var sight_range := 380.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var key: Sprite2D = $Key
@onready var ledge_cast: RayCast2D = $LedgeCast
@onready var wind_player: AudioStreamPlayer2D = $WindPlayer

var _state := State.WALK
var _state_left := 0.0
var _rest_left := 0.0
var _direction := -1.0
var _key_t := 0.0
var _feet_t := 0.0
var _key_x := 0.0
var _ledge_x := 0.0

func _ready() -> void:
	add_to_group("enemies")
	_key_x = absf(key.position.x)
	_ledge_x = absf(ledge_cast.position.x)
	_face_direction()

func _physics_process(delta: float) -> void:
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	if not is_on_floor():
		velocity.y += gravity * delta
	_update_state(delta)
	var speed := 0.0
	match _state:
		State.WALK:
			speed = walk_speed
		State.DASH:
			speed = dash_speed
	velocity.x = _direction * speed
	move_and_slide()
	if is_on_floor() and (is_on_wall() or not ledge_cast.is_colliding()):
		_turn()
	_animate(delta, speed)

func _update_state(delta: float) -> void:
	_rest_left = maxf(_rest_left - delta, 0.0)
	_state_left -= delta
	match _state:
		State.WALK:
			if _rest_left <= 0.0 and is_on_floor():
				_look_for_player()
		State.WIND_UP:
			if _state_left <= 0.0:
				_set_state(State.DASH, dash_time)
		State.DASH:
			if _state_left <= 0.0:
				_end_dash()

func _look_for_player() -> void:
	var player := EnemyKit.player(self)
	if player == null:
		return
	var to_player := player.target_position() - global_position
	if absf(to_player.x) > sight_range or absf(to_player.y) > SIGHT_HEIGHT:
		return
	if signf(to_player.x) != _direction:
		_direction = signf(to_player.x)
		_face_direction()
	_set_state(State.WIND_UP, wind_up_time)
	EnemyKit.play_sound(wind_player)

func _set_state(state: State, duration: float) -> void:
	_state = state
	_state_left = duration

func _end_dash() -> void:
	_set_state(State.WALK, 0.0)
	_rest_left = dash_rest

func _turn() -> void:
	_direction = -_direction
	_face_direction()
	if _state == State.DASH:
		_end_dash()

# The art faces right.
func _face_direction() -> void:
	sprite.flip_h = _direction < 0.0
	key.flip_h = sprite.flip_h
	key.position.x = -_direction * _key_x
	ledge_cast.position.x = _direction * _ledge_x

func _animate(delta: float, speed: float) -> void:
	_key_t += delta * KEY_FPS[_state]
	key.frame = int(_key_t) % key.hframes
	_feet_t += delta * speed / FEET_STEP
	sprite.frame = int(_feet_t) % sprite.hframes
	# Shiver while winding up
	sprite.position.x = randf_range(-1.0, 1.0) if _state == State.WIND_UP else 0.0

func hit_by_projectile(_projectile: Projectile) -> void:
	hit_points -= 1
	if hit_points <= 0:
		EnemyKit.explode(self)
	else:
		EnemyKit.flash(sprite)
