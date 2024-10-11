extends ProjectileRay

@export var damaging_explosion:PackedScene

@export var default_timeout:float = 2.0
# Plus or minus on the explosion timer for variety
@export var target_range_plus_minus:float = 0.3

# Override parent class
func set_data(dat:ShootData) -> void:
	super.set_data(dat)
	# If there is a target, assess distance to
	# target and set timer to start with a semi-random
	# time that will cause an explosion near the target
	if dat.target:
		var dist := global_position.distance_to(dat.target.global_position)
		var timeout := (dist/speed) # + randf_range(-target_range_plus_minus,target_range_plus_minus) #TODO
		$Timer.stop()
		$Timer.start(timeout)
		#print()
		#print(timeout) #TODO
		#print($Timer.wait_time)
		#print(dist)
		#print(speed)
	else:
		$Timer.start(default_timeout)


# Explode on timeout
func _on_timer_timeout() -> void:
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
	# Wait until the end of the frame to execute queue_free
	Callable(queue_free).call_deferred()
