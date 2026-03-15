extends MissileLock


# Takes on-screen position of target as input
func start_seeking(target_onscreen:Vector2) -> void:
	# Make reticle approach the target from the far side of
	# center screen relative to the target's on-screen position.
	# First, get the position of the target as if 0,0 was center screen
	reticle_position = (DisplayServer.window_get_size()/2.0) - target_onscreen
	# Then adjust that position to the far side of center.
	reticle_position = distance_multiplier*reticle_position + target_onscreen


# Move reticle into position and, if it's close enough,
# acquire lock. Move toward target linearly.
func continue_seeking(delta:float, target_onscreen:Vector2,
		targeter:Node3D, acquiring:TextureRect) -> void:
	# Move reticle toward target
	reticle_position = reticle_position.move_toward(target_onscreen, delta*speed)
	# "acquiring" is the reticle. Position it on screen
	acquiring.set_global_position(reticle_position - acquiring_offset)
	# Check if lock acquired
	dist_tween_reticles = target_onscreen.distance_squared_to(reticle_position)
	#print(int(sqrt(dist_tween_reticles)))
	if dist_tween_reticles < lock_dist_sqd:
		lock_acquired.emit(targeter)


func stop_seeking() -> void:
	pass
	
