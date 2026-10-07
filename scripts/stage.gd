extends Node2D
class_name Stage

## One area of a level: the outdoor stage, or a cave reached through a door. main.gd frames the
## camera, the sky and the fall limit to the area Tanky is in.

## Background colour behind the tiles.
@export var sky_color := Color(0.27450982, 0.7372549, 0.9882353)
## Caves stop the camera at their ceiling; outdoors the top stays open for jumps.
@export var has_ceiling := false

func _ready() -> void:
	add_to_group("stages")

## World-space rectangle covered by every tile layer of this area.
func bounds() -> Rect2:
	var result := Rect2()
	var has_bounds := false
	for node in find_children("*", "TileMapLayer", true, false):
		var layer := node as TileMapLayer
		var used := layer.get_used_rect()
		if layer.tile_set == null or not used.has_area():
			continue
		var tile_size := Vector2(layer.tile_set.tile_size)
		var local := Rect2(Vector2(used.position) * tile_size, Vector2(used.size) * tile_size)
		var layer_bounds := layer.global_transform * local
		result = result.merge(layer_bounds) if has_bounds else layer_bounds
		has_bounds = true
	return result
