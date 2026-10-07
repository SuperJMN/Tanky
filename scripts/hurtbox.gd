extends Area2D
class_name Hurtbox

## Tanky's damage sensor. Enemy projectiles hit it through the combat contract, and it reports
## enemies that touch it.

## Emitted when an enemy projectile hits; source is where the hit came from.
signal hurt(source: Vector2)

func hit_by_projectile(projectile: Projectile) -> void:
	hurt.emit(projectile.global_position)

## The first enemy overlapping the hurtbox, or null.
func touching_enemy() -> Node2D:
	for area in get_overlapping_areas():
		if area.is_in_group("enemies"):
			return area
	for body in get_overlapping_bodies():
		if body.is_in_group("enemies"):
			return body
	return null
