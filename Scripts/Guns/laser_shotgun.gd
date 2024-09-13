extends Gun
class_name LaserShotgun

# Here I want to create a "laser" shotgun
# (by which I mean a hitscan shotgun)
# like house of the dying sun's blunderbuss

# IMPORTANT NOTE:
# Bullet bits should be put in place of any other
# bullet in the "bullet" packed scene.

# Damage is dealt in the bulletbits so that
# it looks a little more realistic. The
# bulletbits never miss and will deal damage when
# they reach the target. There is some travel time
# even though the hit is determined by raycast
# in this script.

# Bullet bits are part animation, part actual damage
# dealer. However, it's predetermined when they get
# created whether they hit their target or not based
# on the raycasts in the laser shotgun

# number of bullets per shot.
@export var bullets := 8
# Range of this weapon
@export var gun_range:float = 300.0

# GPU particles to spawn on point of impact:
@export var sparks:PackedScene # Not currently in use


func _ready() -> void:
	# Create all the necessary raycasts
	for i in range(bullets):
		ray = RayCast3D.new()
		$RayCastGroup.add_child(ray)
		ray.collide_with_areas = true
		ray.target_position = Vector3(0,0,-gun_range)
		# Disable collision mask 1
		ray.set_collision_mask_value(1,false)
		# Enable collision masks 2, 4
		ray.set_collision_mask_value(2,true)
		ray.set_collision_mask_value(4,true)
		# Pre rotate all the raycasts. For unknown
		# reasons, if you don't do this, the first
		# shot will all be clustered in a straight
		# line EVEN THOUGH I later rotate before
		# getting collision points. Just do it here
		# and don't worry about it. It's way too
		# much headache to track down whatever the
		# issue is. Chalk it up to some aspect of
		# raycasts I don't understand.
		ray.rotation_degrees = Vector3(
				randf_range(-spread_deg,spread_deg),
				randf_range(-spread_deg,spread_deg),
				0.0)


# Override parent class's shoot_actual
func shoot_actual() -> void:
	if firing:
		firing = false
		# Loop through all the raycasts
		# and BulletBits.
		var bulletbit:BulletBit
		for i in range(bullets):
			# Create a bullet
			bulletbit = bullet.instantiate()
			get_tree().get_root().add_child(bulletbit)
			# Access ith raycast
			ray = $RayCastGroup.get_child(i)
			# Rotate the ray a random amount
			ray.rotation_degrees = Vector3(
					randf_range(-spread_deg,spread_deg),
					randf_range(-spread_deg,spread_deg),
					0.0)
			# The following if has not yet been used or tested
			if ray.is_colliding():
				# Spawn sparks on location of hit
				if sparks:
					var spark = sparks.instantiate()
					add_child(spark)
					spark.global_position = ray.get_collision_point()
				# set_up tells the bullet bit where to start,
				# where to end, and activates it so it rushes
				# to its target.
				bulletbit.set_up(global_position, ray.get_collision_point(), ray.get_collision_normal(), ray.get_collider())
			else:
				bulletbit.set_up(global_position, global_position+ray.global_transform.basis.z * ray.target_position.z, ray.get_collision_normal(), null)
