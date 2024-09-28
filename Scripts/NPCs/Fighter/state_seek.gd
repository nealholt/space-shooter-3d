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

# Angle at which to start scaling down pitch amount
# This may be undesirable. I'm turning it off for
# now by setting it to zero.
const pitch_threshold_angle:float = deg_to_rad(0)

# float in the range 0 to 1 at which to start scaling
# up the pitch. Don't pitch much until most of the roll
# is completed. This is a percent. Below this percent,
# start pitching
const pitch_begins:float = 0.1

# This function should contain code to be
# executed at the start of the state,
# any set up that needs performed.
func Enter() -> void:
	motion.reset()
	# Set intermediate speed
	motion.goal_speed = 0.5
	# Set a timelimit for seeking
	time_limit = 30.0 # seconds

# This function should be called on each
# physics update frame.
func Physics_Update(delta:float) -> void:
	# Update npc and target info
	update_data()
	# Get the x angle to target
	# This is the side to side. Ideally yaw would handle this
	# but I think it looks better if we pitch and roll.
	var x_angle:float = Global.get_angle_to_target(my_pos, target_pos, basis.x)
	# Determine roll
	# x_angle of zero is directly to our right.
	# Angle between -90 and 90 means the target
	# is somewhere off to the right and we should
	# roll clockwise to get it above us in anticipation
	# of pitching up.
	# Otherwise roll counterclockwise.
	#motion.goal_roll = x_angle/ninety_degrees - 1 # angle over pi/2 - 1 maps 0 to pi (180) onto -1 to 1
	motion.goal_roll = sin(x_angle-ninety_degrees) # but this also maps 0 to pi (180) onto -1 to 1 and I think it has a better curve
	#Don't begin the pitch until most of the roll is completed.
	if abs(motion.goal_roll) < pitch_begins:
		# Get the y angle to target
		var y_angle:float = Global.get_angle_to_target(my_pos, target_pos, basis.y)
		# Determine pitch
		# y_angle of zero is directly above.
		# Angle between -90 and 90 means the target
		# is somewhere above and we should pitch up.
		# Otherwise pitch down.
		print('y_angle in seek (degrees)')
		print(round(rad_to_deg(y_angle)))
		if y_angle < 90:
			motion.goal_pitch = 1.0
		else:
			motion.goal_pitch = -1.0
	# Get the z angle to target
	var z_angle:float = Global.get_angle_to_target(my_pos, target_pos, -basis.z)
	# If the angle is under threshold, start reducing the pitch.
	if z_angle < pitch_threshold_angle:
		motion.goal_pitch *= abs(z_angle)/pitch_threshold_angle
	# Check for state exit. Transition to lockon
	# when the angle is low enough.
	if z_angle < close_enough_angle:
		#print('transitioning from seek to lockon')
		Transitioned.emit(self,"lockon")
	# Transition to flee if too close
	if dist_sqd < too_close_sqd:
		Transitioned.emit(self,"flee")
	# Time out
	elapsed_time += delta
	if elapsed_time >= time_limit:
		#print('transitioning from seek to evasion')
		choose_random_evasion()
