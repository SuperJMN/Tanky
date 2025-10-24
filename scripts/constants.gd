extends Node

# Global game constants
var ground_top: float = 425.0  # Ground is at y=450, minus some margin
const GRAVITY: float = 800.0

func _ready():
	# Ground is a StaticBody2D at y=450
	ground_top = 425.0
