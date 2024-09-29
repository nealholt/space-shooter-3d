extends State

# This is basically going to be the inverse of seek
# Roll/yaw/pitch away from target and accelerate to
# max until timeout or max_distance reached.
# If max_distance reached, transition to seek.
# If timeout reached, transition to a random evasion.

const distance_limit_sqd:float = 500.0**2 # meters

# This function should contain code to be
# executed at the start of the state,
# any set up that needs performed.
func Enter() -> void:
	motion.reset()
	elapsed_time = 0.0
	time_limit = 30.0 # seconds
	# Set intermediate speed
	motion.goal_speed = 1.0

# This function should be called on each
# physics update frame.
func Physics_Update(delta:float) -> void:
	pass #TODO
	## Determine pitch
	## y_angle of zero is directly above.
	## Angle between -90 and 90 means the target
	## is somewhere above and we should pitch down.
	## Otherwise pitch up. Opposite of seek.
	## Pitch away from target
	#if y_angle < ninety_degrees:
		#motion.goal_pitch = abs(PI - z_angle)
	#else:
		#motion.goal_pitch = -abs(PI - z_angle)
	#
	## Check for state exit
	#if dist_sqd > distance_limit_sqd:
		##print('transitioning from flee to seek')
		#Transitioned.emit(self,"seek")
	#elapsed_time += delta
	#if elapsed_time > time_limit:
		##print('ERROR should not occur in state_flee')
		#choose_random_evasion()
