extends Gun
class_name HitScanGun

# The following code initially based on the hitscan
# weapon from the FPS tutorial here:
# https://www.udemy.com/course/complete-godot-3d/

# GPU particles to spawn on point of impact.
# Normally this would be in the bullet, but
# there is no bullet.
@export var sparks:VisualEffectSetting.VISUAL_EFFECT_TYPE
# For now, every hitscan weapon has a laser beam
@export var laser_mesh: MeshInstance3D
@export var laser_mesh_pivot: Node3D

func _ready():
	super._ready()
	if !ray:
		printerr('This gun requires an attached RayCast3D child that is connect to the ray export variable.')
	# Disable the ray for efficiency. Otherwise the
	# ray checks for collisions on every physics
	# update. Instead, only check for collisions
	# when the gun fires using force_raycast_update
	ray.enabled = false

# Override parent class's shoot_actual
func shoot_actual() -> void:
	ray.force_raycast_update() # Check for collisions
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider.is_in_group("damageable"):
			#print("dealt damage")
			collider.damage(damage, data.shooter)
		# Spawn sparks on location of hit
		VfxManager.play(muzzle_flash, ray.get_collision_point())
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


# Override parent class's function
func deactivate() -> void:
	super.deactivate()
	laser_mesh.visible = false
