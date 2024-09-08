extends Node3D

# Here I want to create a "laser" shotgun
# (by which I mean a hitscan shotgun)
# like house of the dying sun's blunderbuss

@export var spread := 5.0 # +/- this many degrees
@export var fire_rate := 5.0 # number of times to fire per second
@export var bullets := 8 # number of bullets per shot
@export var weapon_damage := 1
@export var muzzle_flash:GPUParticles3D
# GPU particles to spawn on point of impact:
@export var sparks:PackedScene

@onready var cooldown_timer: Timer = $CooldownTimer

#True if the gun has received command to fire
var firing: bool = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if firing:
		firing = false
		if muzzle_flash:
			muzzle_flash.restart()
		cooldown_timer.start(1.0/fire_rate)
		# Loop through all the raycasts
		# and meshinstances.
		var ray:RayCast3D
		#var beam:MeshInstance3D
		var collider
		for i in range(bullets):
			ray = $Raycasts.get_child(i)
			ray.rotation_degrees = Vector3(
					randf_range(-spread,spread),
					randf_range(-spread,spread),
					0.0)
			collider = ray.get_collider()
			if ray.is_colliding():
				if collider.is_in_group("damageable"):
					#print("dealt damage")
					collider.damage(1)
				# Spawn sparks on location of hit
				if sparks:
					var spark = sparks.instantiate()
					add_child(spark)
					spark.global_position = ray.get_collision_point()
			# Whether or not there is a collision,
			# position and draw the "laser"
			#beam = $Visuals.get_child(i)
			#beam.rotation_degrees = ray.rotation_degrees
			#beam.rotation_degrees.x += 90
			# When the raycast rotates, it rotates from
			# its starting point. But when a mesh rotates,
			# it rotates from its middle, so then we need
			# to move it forward along its new z direction
			# by half of its length
			#print()
			#print(beam.global_position)
			#beam.global_position = global_position # Reset
			#beam.global_position -= beam.global_transform.basis.z * beam.mesh.get_height()
			#print(beam.global_position)
			#beam.position.z = -beam.mesh.get_height()


# https://www.udemy.com/course/complete-godot-3d/learn/lecture/41088242#questions
# Returns true if successful. The return is useful for
# animations and sounds
func shoot(_shoot_data:ShootData) -> void:
	if cooldown_timer.is_stopped():
		firing = true
