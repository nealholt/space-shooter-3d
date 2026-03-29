class_name StateAvoid extends State
# Transition to this state to avoid an obstacle.

# 3 different rays: ahead, above, and below
# When ahead ray detects a collision
# check other two rays
# If one is not blocked, pitch up or down depending on which is not blocked.
# If both are blocked, slow down and randomly pitch up or down AND roll.
# Continue motion until ahead ray is no longer blocked, at that point, transition temporarily into straight line motion before seeking again.
# THIS WORKS UNDER SOME CIRCUMSTANCES, BUT IT'S NOT VERY GENERAL

var obstacle_detector:ObstacleDetector

# This function should contain code to be
# executed at the start of the state,
# any set up that needs performed.
func Enter() -> void:
	super.Enter() # Resets motion to all zero
	# Maintain high speed while avoiding
	motion.goal_speed = 1.0
	# Don't allow interruptions to avoiding
	motion.can_interrupt_state = false
	# If blocked above and below. Reduce speed...
	# and try rolling a little
	if obstacle_detector.get_blocked_above() and obstacle_detector.get_blocked_below():
		#print('blocked above and below') #TESTING
		motion.goal_speed = 0.5
		if random.randi()%2:
			motion.goal_roll = 0.2
		else:
			motion.goal_roll = -0.2
	# If blocked above, pitch down
	elif obstacle_detector.get_blocked_above():
		#print('blocked above') #TESTING
		motion.goal_pitch = -1.0
	# If blocked below, pitch up
	elif obstacle_detector.get_blocked_below():
		#print('blocked below') #TESTING
		motion.goal_pitch = 1.0
	else: # Otherwise blocked neither above nor
		# below, randomly pitch up or down
		#print('blocked neither above nor below') #TESTING
		if random.randi()%2:
			motion.goal_pitch = -1.0
		else:
			motion.goal_pitch = 1.0


# This function should be called on each
# physics update frame.
func Physics_Update(_delta:float) -> void:
	# Reduce pitch to 10% when no longer blocked ahead
	if !obstacle_detector.get_blocked_ahead():
		#print('reduce pitch')
		motion.goal_pitch = motion.goal_pitch/10.0
	# When no longer blocked elsewhere, transition out
	# of this state
	if !obstacle_detector.get_blocked_above() and !obstacle_detector.get_blocked_below():
		# No longer blocked at all.
		Transitioned.emit(self, 'seek')
