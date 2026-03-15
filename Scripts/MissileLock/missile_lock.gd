class_name MissileLock extends Node
# Under this missile lock setup, the time it takes to
# get a lock scales linearly with the distance of the
# target from the center of the screen when the lock begins
# to be acquired.
# Screen-centered locks are basically instantaneous.

signal lock_acquired(targeter:Node3D)

# Speed at which reticle approaches target.
# Is false measured in onscreen pixels per second (I think)
@export var speed:float = 500.0
# Squared distance at which to transition
# into the locked state
@export var lock_dist_sqd:float = 4.0
# Distance multiplier for how far from onscreen position
# of target to put the reticle when it's first shown
# on screen.
@export var distance_multiplier:float = 3.0

# Current onscreen position of reticle
var reticle_position:Vector2
# Half the width of the acquiring TextureRect to display it centered
var acquiring_offset:Vector2
# Onscreen distance between reticle and target
var dist_tween_reticles:float
# Scale time between beeps with reticle distance to target
var distance_scaling: = 70.0**2


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


# Scale the audio delay with distance to target.
# Return a value between repeat_tone_min_time and repeat_tone_max_time
func get_audio_delay(repeat_tone_min_time:float, repeat_tone_max_time:float) -> float:
	return min(dist_tween_reticles/distance_scaling, 1.0) * (repeat_tone_max_time - repeat_tone_min_time) + repeat_tone_min_time
