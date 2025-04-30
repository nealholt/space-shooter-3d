extends State

# This is basically going to be the inverse of seek
# Roll/yaw/pitch away from target and accelerate to
# max until timeout or max_distance reached.
# If max_distance reached, transition to seek.
# If timeout reached, transition to a random evasion.

var distance_limit_sqd:float = 150.0**2 # meters

# This function should contain code to be
# executed at the start of the state,
# any set up that needs performed.
func Enter() -> void:
	super.Enter()
	time_limit = 15.0 # seconds
	# Set intermediate speed
	motion.goal_speed = 1.0

# This function should be called on each
# physics update frame.
func Physics_Update(delta:float) -> void:
	# Pitch away from target
	pitch_target_behind()
	
	# Transition to seek if distance limit is reached
	if motion.orientation_data.dist_sqd > distance_limit_sqd:
		#print('transitioning from flee to seek')
		Transitioned.emit(self,"seek")
	# Choose a random evasion if timeout occurs
	elapsed_time += delta
	if elapsed_time > time_limit:
		choose_random_evasion()
