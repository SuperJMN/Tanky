class_name EnemyKit

## Helpers shared by every enemy: finding Tanky, hit feedback and death.

const EXPLOSION_SCENE := preload("res://scenes/explosion.tscn")
const FLASH_COLOR := Color(4.0, 4.0, 4.0)
const FLASH_TIME := 0.15
const SCREEN_MARGIN := 64.0  # px around the screen where enemies can still be heard

## Tanky while he is alive, or null.
static func player(from: Node) -> Tanky:
	var tanky := from.get_tree().get_first_node_in_group("player") as Tanky
	return tanky if tanky and tanky.is_alive() else null

## Play an enemy sound only when the enemy is on screen, so far-away enemies stay silent.
static func play_sound(sound: AudioStreamPlayer2D) -> void:
	var screen := sound.get_viewport_rect().grow(SCREEN_MARGIN)
	if screen.has_point(sound.get_global_transform_with_canvas().origin):
		sound.play()

## Flash white after a hit that did not destroy the enemy.
static func flash(item: CanvasItem) -> void:
	item.modulate = FLASH_COLOR
	item.create_tween().tween_property(item, "modulate", Color.WHITE, FLASH_TIME)

## Blow the enemy up and remove it.
static func explode(enemy: Node2D) -> void:
	if enemy.is_queued_for_deletion():
		return
	var fx: Node2D = EXPLOSION_SCENE.instantiate()
	fx.global_position = enemy.global_position
	enemy.get_tree().current_scene.add_child(fx)
	enemy.queue_free()
