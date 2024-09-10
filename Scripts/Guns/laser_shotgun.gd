extends Node3D

# Here I want to create a "laser" shotgun
# (by which I mean a hitscan shotgun)
# like house of the dying sun's blunderbuss

# Damage is dealt in the bulletbits so that
# it looks a little more realistic. The bulletbits
# should never miss and will deal damage when
# they reach the target. There is some travel time
# even though the hit is determined by raycast
# in this script.

# Visuals is a Node, not a Node3D because I don't
# want the bulletbits to inherit position and
# direction information. If they did, then they
# would move when the shooter moves and that would
# be no good.

# +/- this many degrees:
@export var spread := 5.0
# number of times to fire per second:
@export var fire_rate := 5.0
# number of bullets per shot.
@export var bullets := 8
# Range of this weapon
@export var gun_range:float = 300.0

@export var muzzle_flash:GPUParticles3D # Not currently in use
# GPU particles to spawn on point of impact:
@export var sparks:PackedScene # Not currently in use

@onready var cooldown_timer: Timer = $CooldownTimer

#True if the gun has received command to fire
var firing: bool = false


func _ready() -> void:
	# Pre rotate all the raycasts. For unknown
	# reasons, if you don't do this, the first
	# shot will all be clustered in a straight
	# line EVEN THOUGH I later rotate before
	# getting collision points. Just do it here
	# and don't worry about it. It's way too
	# much headache to track down whatever the
	# issue is. Chalk it up to some aspect of
	# raycasts I don't understand.
	var ray:RayCast3D
	for i in range(bullets):
		# Create all the necessary raycasts
		ray = RayCast3D.new()
		$Raycasts.add_child(ray)
		ray.collide_with_areas = true
		ray.target_position = Vector3(0,0,-gun_range)
		# Disable collision mask 1
		ray.set_collision_mask_value(1,false)
		# Enable collision masks 2, 4
		ray.set_collision_mask_value(2,true)
		ray.set_collision_mask_value(4,true)
		#ray = $Raycasts.get_child(i) #TODO this is the old way
		ray.rotation_degrees = Vector3(
				randf_range(-spread,spread),
				randf_range(-spread,spread),
				0.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if firing:
		firing = false
		if muzzle_flash:
			muzzle_flash.restart()
		cooldown_timer.start(1.0/fire_rate)
		# Loop through all the raycasts
		# and BulletBits.
		var ray:RayCast3D
		var bulletbit:BulletBit
		for i in range(bullets):
			# Use the ith ray and bullet
			bulletbit = $Visuals.get_child(i)
			ray = $Raycasts.get_child(i)
			# Rotate the ray a random amount
			ray.rotation_degrees = Vector3(
					randf_range(-spread,spread),
					randf_range(-spread,spread),
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


func shoot(_shoot_data:ShootData) -> void:
	firing = cooldown_timer.is_stopped()
