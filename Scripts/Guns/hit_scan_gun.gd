extends Gun
class_name HitScanGun

# The following code initially based on the hitscan
# weapon from the FPS tutorial here:
# https://www.udemy.com/course/complete-godot-3d/

# GPU particles to spawn on point of impact.
# Normally this would be in the bullet, but
# there is no bullet.
@export var sparks:PackedScene
# For now, every hitscan weapon has a laser beam
@export var laser_mesh: MeshInstance3D
@export var laser_mesh_pivot: Node3D

# Override parent class's shoot_actual
func shoot_actual() -> void:
	var collider = ray.get_collider()
	if ray.is_colliding():
		if collider.is_in_group("damageable"):
			#print("dealt damage")
			collider.damage(1)
		# Spawn sparks on location of hit
		if sparks:
			var spark = sparks.instantiate()
			get_tree().get_root().add_child(spark)
			spark.global_position = ray.get_collision_point()
	position_laser()


func position_laser() -> void:
	# The idea here is to put the Head node at
	# the position and orientation of the gun,
	# but the interleaving generic Node disconnects
	# its children from the movement of the parent
	# (Inspired by this post:
	# https://www.reddit.com/r/godot/comments/ml7bhk/how_to_make_a_child_position_independent_from/
	# )
	# I wanted this so that the laser lingers in space
	# where it was fired, rather than firing and
	# continuing to move with the ship.
	laser_mesh_pivot.global_position = global_position
	laser_mesh_pivot.global_transform = global_transform
	# Change laser mesh length and position relative to Head
	# so the laser doesn't appear to pass through what it hits
	if ray.is_colliding():
		var length = global_position.distance_to(ray.get_collision_point())
		laser_mesh.position.z = -length/2
		laser_mesh.mesh.set_height(length)
	else:
		# Default position and length:
		laser_mesh.position.z = -500
		laser_mesh.mesh.set_height(1000)
