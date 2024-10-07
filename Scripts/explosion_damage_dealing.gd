extends Node3D
class_name ExplosionDamaging

@export var explosion_vfx:PackedScene

var damage_amt:float = 1

# Use this to delete the scene after dealing
# damage OR after two runs through _process.
var delete_me:bool = false

func _process(delta: float) -> void:
	if !delete_me:
		# Add an explosion to main_3d and properly
		# queue free this ship
		var explosion = explosion_vfx.instantiate()
		# Add to main_3d, not root, otherwise the added
		# node might not be properly cleared when
		# transitioning to a new scene.
		Global.main_scene.main_3d.add_child(explosion)
		explosion.global_position = global_position
	# Damage all overlapping bodies
	for body in $Area3D.get_overlapping_bodies():
		if body.is_in_group("damageable"):
			body.damage(damage_amt)
			delete_me = true
	# Damage all overlapping areas
	for area in $Area3D.get_overlapping_areas():
		if area.is_in_group("damageable"):
			area.damage(damage_amt)
			delete_me = true
	# Wait until the end of the frame to execute queue_free
	if delete_me:
		Callable(queue_free).call_deferred()
	delete_me = true
