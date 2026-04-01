class_name StateSeek extends State

# This is working great but could be tweaked further.
# Would a mild yaw make it more accurate? probably
# You should use some yaw.

# Roll and pitch to face target.

# Distance at which to peel off, flee, before
# coming back around for another pass.
# This value is over-written by the npc_state_controller
var too_close_sqd := 30.0**2 # Squared for efficiency

# This function should contain code to be
# executed at the start of the state,
# including any set up that needs performed.
func Enter() -> void:
	super.Enter()
	motion.goal_speed = 1.0 # Top speed

# This function should be called on each
# physics update frame.
func Physics_Update(_delta:float) -> void:
	# Transition to avoid if blocked ahead
	if obstacle_detector and obstacle_detector.get_blocked_ahead():
		Transitioned.emit(self,"avoid")
		return
	# Transition to flee if too close to target
	if motion.orientation_data.dist_sqd < too_close_sqd:
		#print('transitioning from seek to flee')
		Transitioned.emit(self,"flee")
		return
	# Roll to get target above us.
	roll_target_above()
	# Pitch toward target.
	pitch_target_ahead()
	# Yaw to get target ahead
	yaw_target_ahead()
