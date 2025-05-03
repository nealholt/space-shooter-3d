extends Projectile
class_name ProjectileRay

# Improvements made to my code based on this
# excellent tutorial:
# Raycast bullets in Godot 4 by ImmersiveRPG
# https://www.youtube.com/watch?v=joMBVo_ZwKI

const MIN_RAY_DISTANCE := 1.0

@onready var ray:RayCast3D = $RayCast3D

@export var does_ricochet:bool = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Move bullet
	super._physics_process(delta)
	# Change ray position and length to extend from
	# previous bullet position to new position.
	var distance := velocity.length() * delta
	# Also make the ray at least minimum length
	if distance < MIN_RAY_DISTANCE:
		ray.target_position.z = -MIN_RAY_DISTANCE
		ray.transform.origin.z = MIN_RAY_DISTANCE
	else:
		ray.target_position.z = -distance
		ray.transform.origin.z = distance
	# Check for and handle collisions.
	if ray.is_colliding():
		var body := ray.get_collider()
		if !is_instance_valid(body):
			return
		# In order to fire from within a shield, we
		# need to ignore immediate collisions.
		if frame_count <= 1:
			ray.add_exception(body)
			return
		# If we hit a near-miss detector
		if body.is_in_group("near-miss detector"):
			start_near_miss_audio()
			# https://forum.godotengine.org/t/possible-to-detect-multiple-collisions-with-raycast2d/27326/2
			# Add body to ray's exception list. This way
			# the ray can detect something behind the body.
			ray.add_exception(body)
			# Update the ray's collision query.
			ray.force_raycast_update()
			# If it's still colliding...
			if ray.is_colliding():
				# ...get the new collider
				body = ray.get_collider()
			else: # Otherwise return
				return
		if passes_through(body):
			pass
		elif body.is_in_group("damageable"):
			# Stick on a decal before damaging and dying
			# Don't stick decals on shields
			if !body.is_in_group("shield"):
				VfxManager.play_at_angle(bullet_hole_decal, ray.get_collision_point(), ray.get_collision_normal())
			damage_and_die(body, ray.get_collision_point())
		# Ricochet
		elif does_ricochet:
			ricochet(delta)
		else:
			pass


# Source at 6:30 here:
# https://www.youtube.com/watch?v=joMBVo_ZwKI
# It seems that the second ricochet is glitchy,
# though the first bounce works as expected.
# For now I'm moving on.
func ricochet(delta:float):
	# Move the bullet back to the point of collision
	global_position = ray.get_collision_point()
	# Remove 20% of the speed
	#speed = clampf(speed - speed*0.2, 0.0, 100000.0)
	#velocity = -transform.basis.z * speed
	# Bounce
	var norm := ray.get_collision_normal()
	velocity = velocity.bounce(norm)
	# In the video, the creator uses Global.safe_look_at
	# which I assume is something he created after
	# getting errors from using look_at
	# You might consider creating your own
	# based on the code in the stick_decal function
	# which also had to deal with look_at bugs.
	look_at(global_transform.origin - velocity)
	# Move away from collision location to avoid
	# touching it on the next frame.
	# 1.1 to give that 10% extra assurance of not
	# recolliding.
	global_position += velocity * delta * 1.1
