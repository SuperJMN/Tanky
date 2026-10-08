extends Area2D
class_name Door

## Doorway to another area of the level, such as a cave. When Tanky stands in it and the player
## presses up (`enter_door`), main.gd fades the screen out and brings him out at the exit.

signal entered(door: Door)

## Where Tanky comes out: a point inside the bounds of the target Stage, clear of its doors.
@export_node_path("Node2D") var exit_path: NodePath
@onready var exit: Node2D = get_node(exit_path)

func _ready() -> void:
	add_to_group("doors")

func _physics_process(_delta: float) -> void:
	if not Input.is_action_pressed("enter_door"):
		return
	for body: Node2D in get_overlapping_bodies():
		if body.get_parent() is Tanky:
			entered.emit(self)
			return
