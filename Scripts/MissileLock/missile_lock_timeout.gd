extends MissileLock
# Under this missile lock setup, there's a fixed time to
# acquire lock no matter what you do. No skill involved
# besides keeping the target within the maximum angle of
# screen center.
# The reticle itself bounces randomly within a steadily
# decreasing radius of the target reticle.
# I originally meant for the reticle to slide around within
# the circle, but this is cool in its own right.

const TIME_TO_LOCK:float = 1.0 ## Time in seconds to acquire a lock
const RETICLE_DISTANCE:float = 200.0 ## Distance in pixels to start reticle from the target

var lock_time:float ## Time remaining before lock is acquired
var reticle_radius:float ## Radius of ever-shrinking circle within which reticle moves before lock is acquired

# Takes on-screen position of target as input
func start_seeking(target_onscreen:Vector2) -> void:
	# Start off the reticle at a random angle from the
	# target_onscreen position, at max distance
	reticle_radius = RETICLE_DISTANCE # Reset
	lock_time = TIME_TO_LOCK # Reset
	var angle:float = randf_range(0,2*PI) # Random angle
	reticle_position = target_onscreen + Vector2(cos(angle),sin(angle))*reticle_radius


# Move reticle randomly within shrinking reticle_radius.
# When lock_time reaches zero, acquire lock
func continue_seeking(delta:float, target_onscreen:Vector2,
		targeter:Node3D, acquiring:TextureRect) -> void:
	# Countdown to lock
	lock_time -= delta
	if lock_time <= 0.0:
		lock_acquired.emit(targeter)
	# Reposition reticle
	reticle_radius = RETICLE_DISTANCE * (lock_time / TIME_TO_LOCK)
	var angle:float = randf_range(0,2*PI) # Random angle
	reticle_position = target_onscreen + Vector2(cos(angle),sin(angle))*reticle_radius
	acquiring.set_global_position(reticle_position - acquiring_offset)
