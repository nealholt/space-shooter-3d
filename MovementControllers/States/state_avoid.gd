class_name StateAvoid extends State
# Transition to this state to avoid an obstacle.

# 3 different rays: ahead, above, and below
# When ahead ray detects a collision
# check other two rays
# If one is not blocked, pitch up or down depending on which is not blocked.
# If both are blocked, slow down and randomly pitch up or down AND roll.
# Continue motion until ahead ray is no longer blocked, at that point, transition temporarily into straight line motion before seeking again.
# THIS WORKS UNDER SOME CIRCUMSTANCES, BUT IT'S NOT VERY GENERAL

# This function should contain code to be
# executed at the start of the state,
# any set up that needs performed.
func Enter() -> void:
	super.Enter() # Resets motion to all zero
	# Use this as a minimum amount of time to remain
	# in the avoid state, otherwise, rapid oscillation
	# between seek and avoid can occur. A better
	# alternative might be to reduce the size of the 
	# "ahead" raycast
	time_limit = 2.0 # seconds
	# Maintain high speed while avoiding
	motion.goal_speed = 1.0
	# Don't allow interruptions to avoiding
	motion.can_interrupt_state = false
	
	var blocked_above:bool = obstacle_detector.get_blocked_above()
	var blocked_below:bool = obstacle_detector.get_blocked_below()
	# If blocked above and below, or blocked neither
	# above nor below, then pitch up or down randomly
	if (blocked_above and blocked_below) or (!blocked_above and !blocked_below):
		# below, randomly pitch up or down
		if random.randi()%2:
			motion.goal_pitch = -1.0
		else:
			motion.goal_pitch = 1.0
	# If blocked above, pitch down
	elif obstacle_detector.get_blocked_above():
		motion.goal_pitch = -1.0
	# else only blocked below, pitch up
	else: #if obstacle_detector.get_blocked_below():
		motion.goal_pitch = 1.0


# This function should be called on each
# physics update frame.
func Physics_Update(delta:float) -> void:
	# Reduce pitch to 1/3 when no longer blocked ahead
	if !obstacle_detector.get_blocked_ahead():
		#print('reduce pitch')
		motion.goal_pitch = motion.goal_pitch/3.0
	# Otherwise if obstacle ahead is target, then
	# transition to flee state immediately.
	elif motion.orientation_data.target == obstacle_detector.get_obstacle_ahead():
		Transitioned.emit(self, 'flee')
		return
	# When no longer blocked elsewhere, transition out
	# of this state, unless time limit has NOT yet elapsed
	elapsed_time += delta
	if time_limit < elapsed_time and !obstacle_detector.get_blocked_above() and !obstacle_detector.get_blocked_below():
		# No longer blocked at all.
		Transitioned.emit(self, 'seek')
