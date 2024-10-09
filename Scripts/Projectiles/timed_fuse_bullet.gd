extends ProjectileRay

@export var damaging_explosion:PackedScene

# TODO Some sort of plus or minus on the explosion distance
var target_range_plus_minus:float

# Override parent class
func set_data(dat:ShootData) -> void:
	super.set_data(dat)
	# If there is a target, assess distance to
	# target and set timer to start with a semi-random
	# time that will cause an explosion near the target
	#TODO

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
