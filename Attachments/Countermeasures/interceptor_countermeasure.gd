class_name InterceptorCountermeasure extends Countermeasure

# Fires off a single-target, missile interceptor.
# Basically the flare from X-Wing vs Tie Fighter.
# Picks nearest incoming missile and intercepts it.
# If no incoming missiles, picks nearest targeter
@onready var gun: Gun = $Gun

func activate_countermeasure(data:ShootData) -> void:
	# If you don't do this next bit then flares will fire
	# toward mouse when in first person mode for the player
	data.force_use_transform = true
	# Set the gun to be the flare gun
	data.set_gun(gun)
	
	# Pick out closest target, preferring projectiles
	var my_target:Node3D = null
	var distance:float = exp(16) # Just some big number
	var temp_dist:float
	remove_invalid_targeters()
	for targeter:Node3D in targeters:
		# If targeter is not a projectile and my_target is set,
		# skip ahead to a better target.
		# Basically: prioritize targeting projectiles unless
		# there's nothing better.
		if !(targeter is Projectile) and my_target: continue
		# If targeter does not have a hit box component,
		# skip ahead to a better target. Does this happen?
		if !is_instance_valid(targeter.hit_box_component): continue
		# If targeter is further from current target, skip it
		temp_dist = global_position.distance_squared_to(targeter.global_position)
		if distance < temp_dist: continue
		# Otherwise, set this target as my target and update distance
		my_target = targeter.hit_box_component
		distance = temp_dist
	
	# Set shoot data's target as hit box component of an
	# incoming missile or ship then shoot
	data.target = my_target
	data.shoot()
