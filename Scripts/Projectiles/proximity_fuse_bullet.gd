extends ProjectileArea

@export var damaging_explosion:PackedScene

# Override
func damage_and_die(body, _collision_point=null):
	if passes_through(body):
		return
	# Play feedback for player if relevant
	Global.player_feedback(body, data)
	# Add an explosion to main_3d and properly
	# queue free this ship
	var explosion = damaging_explosion.instantiate()
	# Add to main_3d, not root, otherwise the added
	# node might not be properly cleared when
	# transitioning to a new scene.
	Global.main_scene.main_3d.add_child(explosion)
	# Set explosion's position and damage
	explosion.global_position = global_position
	explosion.damage_amt = damage
	# I got an invalid assignment on 
	# explosion.shooter = data.shooter
	# so I slapped on this if to try to avoid it.
	if is_instance_valid(data.shooter):
		explosion.shooter = data.shooter
	# Wait until the end of the frame to execute queue_free
	Callable(queue_free).call_deferred()
