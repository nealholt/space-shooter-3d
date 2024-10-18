extends ProjectileRay

@export var damaging_explosion:PackedScene

# Add a random amount in the range of
# plus or minus this percent of bullet timeout
# on the explosion timer for variety
@export var target_range_plus_minus:float = 0.1

# Override parent class
func set_data(dat:ShootData) -> void:
	super.set_data(dat)
	# If there is a target, assess distance to
	# target and set timer to start with a semi-random
	# time that will cause an explosion near the target
	if dat.target and is_instance_valid(dat.target):
		# Get distance to target intercept
		var intercept:Vector3 = Global.get_intercept(
					global_position, speed,
					dat.target)
		var dist := global_position.distance_to(intercept)
		# I have no ducking clue why speed needs multiplied
		# by 2, but I gathered data by manually adjusting
		# the timeout and distance and got the following
		# values to hit the player at a bullet speed of 500:
		# distance, timeout
		# (305.16226,0.295)
		# (219.750885,0.215)
		# (1368.4803,1.369)
		# If you plot those on a line, the line is almost exactly
		# y = x/1000
		# What I'd expect is
		# y = x/500   because speed was 500 for these tests
		# Therefore I multiply the speed by 2 and by God
		# that fixes the overshoot. Still don't know why.
		var timeout := (dist/(speed*2))
		# Add in a random +- to the timeout.
		timeout += randf_range(-timeout*target_range_plus_minus, timeout*target_range_plus_minus)
		$Timer.start(timeout)
	else:
		# If no target, just use default bullet timeout
		$Timer.start(dat.bullet_timeout)


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
