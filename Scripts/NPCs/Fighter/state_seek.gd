extends State

# This is working great but could be tweaked further.
# Would a mild yaw make it more accurate? probably
# You should use some yaw.

# Decelerate to medium speed. Roll and pitch to face
# target. Fade in the roll pitch amount.
# End state when within threshold of target or upon timeout.
# If within threshold, transition to LockOn.
# If timeout, do a random evasion.

# How close angle to target needs to be to transition
# out of this state. Number is in degrees, but
# immediately converted to radians
const close_enough_angle:float = deg_to_rad(5)

# Distance at which to peel off, flee, before
# coming back around for another pass
var too_close_sqd := 30.0**2 # Squared for efficiency

# float in the range 0 to 1 at which to start scaling
# up the pitch. Don't pitch much until most of the roll
# is completed. This is a percent. Above this percent,
# start pitching
const pitch_begins:float = 0.90

# This function should contain code to be
# executed at the start of the state,
# any set up that needs performed.
func Enter() -> void:
	super.Enter()
	# Set intermediate speed
	motion.goal_speed = 0.7
	# Set a timelimit for seeking
	time_limit = 30.0 # seconds

# This function should be called on each
# physics update frame.
func Physics_Update(delta:float) -> void:
	# Roll to get target above us.
	roll_target_above()
	
	#motion.orientation_data.print_data()
	
	# Pitch toward target.
	pitch_target_ahead()
	
	# Transition to flee if too close
	if motion.orientation_data.dist_sqd < too_close_sqd:
		#print('transitioning from seek to flee')
		Transitioned.emit(self,"flee")
	# Time out
	elapsed_time += delta
	if elapsed_time >= time_limit:
		#print('transitioning from seek to evasion')
		choose_random_evasion()
