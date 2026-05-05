extends MissileLock
# Under this missile lock setup, the reticle approaches the
# target rapidly at first then more slowly as it gets close.
# Screen-centered locks are still basically instantaneous.

# Lerping reticle to target has a distinct feel and
# it's not bad. I'm not sure which I prefer so this is an
# alternative to the default that I'm keeping for now.
@export var lerp_modifier:float = 12.0
# lerp_weight accumulates over time until it's at 100 percent
var lerp_weight:float = 0.0


# Move reticle into position and, if it's close enough,
# acquire lock. Lerp toward target.
func continue_seeking(delta:float, target_onscreen:Vector2,
		targeter:Node3D, acquiring:TextureRect) -> void:
	# Lerp reticle toward target
	lerp_weight += delta/lerp_modifier
	reticle_position = lerp(reticle_position, target_onscreen, lerp_weight)
	# "acquiring" is the reticle. Position it on screen
	acquiring.set_global_position(reticle_position - acquiring_offset)
	# Check if lock acquired
	dist_tween_reticles = target_onscreen.distance_squared_to(reticle_position)
	#print(int(sqrt(dist_tween_reticles)))
	if dist_tween_reticles < lock_dist_sqd:
		lock_acquired.emit(targeter)


func stop_seeking() -> void:
	lerp_weight = 0.0
