extends SceneTree

const ProjectileScript = preload("res://scripts/projectile.gd")

var failures := 0


class HitTarget:
	extends Node2D
	var handles_impact := false

	func hit_by_projectile(_projectile) -> bool:
		return handles_impact


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene

	_test_target_can_handle_impact(scene)
	_test_projectile_keeps_default_impact(scene)
	await process_frame

	if failures == 0:
		print("PASS: projectile impact ownership")
	current_scene = null
	scene.queue_free()
	await process_frame
	quit(failures)


func _test_target_can_handle_impact(scene: Node2D) -> void:
	var projectile: Node = _make_projectile(scene)
	var target := HitTarget.new()
	target.handles_impact = true
	scene.add_child(target)
	var children_before := scene.get_child_count()

	projectile._on_hit(target)

	_check(scene.get_child_count() == children_before, "handled hit must not spawn a second impact")
	projectile.free()
	target.free()


func _test_projectile_keeps_default_impact(scene: Node2D) -> void:
	var projectile: Node = _make_projectile(scene)
	var target := HitTarget.new()
	scene.add_child(target)
	var children_before := scene.get_child_count()

	projectile._on_hit(target)

	_check(scene.get_child_count() == children_before + 1, "unhandled hit must spawn the projectile impact")
	projectile.free()
	target.free()


func _make_projectile(scene: Node2D):
	var projectile := ProjectileScript.new()
	var impact_scene := PackedScene.new()
	var impact_template := Node2D.new()
	impact_scene.pack(impact_template)
	impact_template.free()
	projectile.impact_scene = impact_scene
	scene.add_child(projectile)
	return projectile


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
