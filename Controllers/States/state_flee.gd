class_name StateFlee extends State

# This is basically going to be the inverse of seek
# Roll/yaw/pitch away from target and accelerate to
# max until timeout or max_distance reached.
# If max_distance reached, transition to seek.
# If timeout reached, transition to a random evasion.

# This value is over-written by the npc_controller
var distance_limit_sqd:float = 0.0 # meters

# This function should contain code to be
# executed at the start of the state,
# including any set up that needs performed.
func Enter() -> void:
	super.Enter()
	time_limit = 15.0 # seconds

# This function should be called on each
# physics update frame.
func Physics_Update(delta:float) -> void:
	# Transition to avoid if blocked ahead and the obstacle
	# is NOT our current target.
	if obstacle_detector and obstacle_detector.get_blocked_ahead() and \
	motion.orientation_data.target != obstacle_detector.get_obstacle_ahead():
		Transitioned.emit(self,"avoid")
		return
	
	# Transition to seek if distance limit is reached
	# or timeout occurs
	elapsed_time += delta
	if motion.orientation_data.dist_sqd > distance_limit_sqd \
	or elapsed_time > time_limit:
		#print('transitioning from flee to seek')
		Transitioned.emit(self,'attack')
	
	# Else if target is facing us, then pitch so target is
	# above. (So we are moving across enemy's line of sight.)
	# Specifically if target is more than 75% facing us.
	elif motion.orientation_data.amt_target_facing_us > 0.75:
		# TODO TESTING TODO LEFT OFF HERE
		#print('pitching to get target above')
		# Slow slightly for better pitching
		motion.goal_speed = 0.9
		pitch_target_above()
	
	# Otherwise pitch away from target
	else:
		motion.goal_speed = 1.0 # Top speed
		#pitch_target_behind()
		pitch_target_behind_serious() # ignore obstacle detector
		# The reason we need to ignore the obstacle detector is
		# because if we are too close to a target, the obstacle
		# detector can suppress pitching in BOTH directions
		# resulting in a head-on collision with the very
		# object we're trying to avoid.
