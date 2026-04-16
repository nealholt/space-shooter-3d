class_name RayCastForProjectiles extends RayCast3D

# Improvements were made to my code based on this
# excellent tutorial:
# Raycast bullets in Godot 4 by ImmersiveRPG
# https://www.youtube.com/watch?v=joMBVo_ZwKI

# Ray length should be distance traveled plus
# projectile_length
@export var projectile_length := 1.0

@export var does_ricochet:bool = true


func Physics_process(proj:Projectile, delta:float) -> void:
	# Change ray length to extend from previous bullet
	# position through new position.
	target_position.z = -proj.velocity.length() * delta - projectile_length
	
	# Check for and handle collisions.
	if is_colliding():
		var body := get_collider()
		if !is_instance_valid(body):
			return
		# If we hit a near-miss detector
		if body.is_in_group("near-miss detector"):
			proj.start_near_miss_audio()
			# https://forum.godotengine.org/t/possible-to-detect-multiple-collisions-with-raycast2d/27326/2
			# Add body to ray's exception list. This way
			# the ray can detect something behind the body.
			add_exception(body)
			# Update the ray's collision query.
			force_raycast_update()
			# If it's still colliding...
			if is_colliding():
				# ...get the new collider
				body = get_collider()
			else: # Otherwise return
				return
		if body.is_in_group("damageable"):
			# Stick on a decal before damaging and dying
			# Don't stick decals on shields
			if !body.is_in_group("shield"):
				VfxManager.play_at_angle(proj.bullet_hole_decal, get_collision_point(), get_collision_normal())
			proj.damage_and_die(body, get_collision_point())
		# Ricochet
		elif does_ricochet:
			proj.ricochet(delta)
