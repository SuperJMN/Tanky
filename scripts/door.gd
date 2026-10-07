extends Area2D
class_name Door

## Doorway to another area of the level, such as a cave. When Tanky drives into it, main.gd
## fades the screen out and brings him out at the exit.

signal entered(door: Door)

## Where Tanky comes out: a point inside the bounds of the target Stage, clear of its doors.
@export_node_path("Node2D") var exit_path: NodePath
@onready var exit: Node2D = get_node(exit_path)

func _ready() -> void:
	add_to_group("doors")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.get_parent() is Tanky:
		entered.emit(self)
