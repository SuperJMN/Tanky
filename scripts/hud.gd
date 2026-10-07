extends CanvasLayer
class_name Hud

## On-screen status: Tanky's health as the cells of a battery.

const PIXEL := 4.0  # screen px per art pixel
const CELL_SIZE := Vector2(4, 6)
const CELL_GAP := 1.0
const OUTLINE := Color(0.094, 0.078, 0.118)
const SHELL := Color(0.886, 0.894, 0.925)
const EMPTY := Color(0.384, 0.4, 0.463)
const CHARGE_COLORS := [  # by remaining health: 1, 2, 3+
	Color(0.91, 0.2, 0.16),
	Color(1.0, 0.87, 0.27),
	Color(0.35, 0.85, 0.35),
]
const LOW_BLINK := 0.25  # s per blink of the last cell
const SHAKE_TIME := 0.3
const SHAKE_PX := 6.0

@export_node_path("Node2D") var battery_path: NodePath
@onready var battery: Node2D = get_node(battery_path)

var _health := 0
var _max_health := 0
var _blink_t := 0.0
var _battery_base := Vector2.ZERO

func _ready() -> void:
	_battery_base = battery.position
	battery.draw.connect(_draw_battery)

func show_health(health: int, max_health: int) -> void:
	var lost := health < _health
	_health = health
	_max_health = max_health
	battery.queue_redraw()
	if lost:
		_shake()

func _process(delta: float) -> void:
	if _health == 1:
		_blink_t += delta
		battery.queue_redraw()

func _shake() -> void:
	var tween := create_tween()
	for i in 4:
		var side := SHAKE_PX if i % 2 == 0 else -SHAKE_PX
		tween.tween_property(battery, "position", _battery_base + Vector2(side, 0.0), SHAKE_TIME / 5.0)
	tween.tween_property(battery, "position", _battery_base, SHAKE_TIME / 5.0)

# Pixel-art battery: outline, shell, terminal nub and one cell per hit.
func _draw_battery() -> void:
	var inner_w := _max_health * (CELL_SIZE.x + CELL_GAP) + CELL_GAP
	var inner := Rect2(Vector2(2, 2), Vector2(inner_w, CELL_SIZE.y + 2.0 * CELL_GAP))
	var shell := inner.grow(1.0)
	_pixel_rect(shell.grow(1.0), OUTLINE)
	_pixel_rect(shell, SHELL)
	_pixel_rect(inner, OUTLINE)
	var nub := Rect2(Vector2(shell.end.x + 1.0, shell.position.y + 2.0), Vector2(2, shell.size.y - 4.0))
	_pixel_rect(nub.grow(1.0), OUTLINE)
	_pixel_rect(nub, SHELL)
	var charge: Color = CHARGE_COLORS[clampi(_health, 1, CHARGE_COLORS.size()) - 1]
	var low_blink_off := _health == 1 and fmod(_blink_t, LOW_BLINK * 2.0) > LOW_BLINK
	for i in _max_health:
		var cell_pos := inner.position + Vector2(CELL_GAP + i * (CELL_SIZE.x + CELL_GAP), CELL_GAP)
		var full := i < _health and not low_blink_off
		_pixel_rect(Rect2(cell_pos, CELL_SIZE), charge if full else EMPTY)
		if full:
			_pixel_rect(Rect2(cell_pos, Vector2(CELL_SIZE.x, 1)), charge.lightened(0.4))

func _pixel_rect(rect: Rect2, color: Color) -> void:
	battery.draw_rect(Rect2(rect.position * PIXEL, rect.size * PIXEL), color)
