class_name State extends Node
# Source:
# https://www.youtube.com/watch?v=ow_Lum-Agbs&t=145s

# This class is both an interface for all states and
# also serves as the stop state.
signal Transitioned

# Reference to an intermediate script through which
# states and the npc moved by the state can communicate.
var motion : MovementProfile

# Random number generator
var random := RandomNumberGenerator.new()

# Elapsed time in this state (Not used by all states)
var elapsed_time:float
# Time limit for this state (Not used by all states)
var time_limit:float

# This is just 90 degrees in radians for efficiency/readability
const ninety_degrees:float = PI/2.0

var in_death_animation:bool = false

# Store npc and target info
var my_pos:Vector3
var target_pos:Vector3
var dist_sqd:float
var basis
# Angles to target in radians
var x_angle:float
var y_angle:float
var z_angle:float
# Booleans for target position relative to npc
var target_is_ahead:bool
var target_is_above:bool
var target_is_right:bool
# Magnitude in indicated direction, in radians
var amt_ahead_behind:float # zero is max ahead. pi (180) is max behind
var amt_above_below:float # zero is inbetween. pi/2 (90) is max above or below
var amt_right_left:float # zero is inbetween. pi/2 (90) is max right or left


func _on_ready() -> void:
	random.randomize()

# This function should contain code to be
# executed at the start of the state,
# any set up that needs performed.
func Enter() -> void:
	motion.reset()
	elapsed_time = 0.0

# This function should contain code to be
# executed at the end of the state,
# any clean up that needs performed.
func Exit() -> void:
	motion.reset()

# This function should be called on each
# physics update frame.
func Physics_Update(_delta:float) -> void:
	pass # Replace with function body.


func enter_death_animation() -> void:
	if !in_death_animation:
		Transitioned.emit(self, 'deathanimation')
		in_death_animation = true


func choose_random_evasion() -> void:
	# If the current state can be interrupted...
	if motion.can_interrupt_state and !in_death_animation:
		# ...then switch into evasion state.
		var x := random.randi() % 3
		if x == 0:
			Transitioned.emit(self, 'jink')
		elif x == 1:
			Transitioned.emit(self, 'wave')
		else:
			Transitioned.emit(self, 'corkscrew')


# Roll to get target above us.
func roll_target_above() -> void:
	if motion.orientation_data.target_is_right:
		motion.goal_roll = -1.0
	else:
		motion.goal_roll = 1.0
	# Reduce rotation when close to ideal angle
	motion.goal_roll = rotation_adjustment(motion.orientation_data.amt_right_left, motion.goal_roll)


# Pitch to get target above
func pitch_target_above() -> void:
	if motion.orientation_data.target_is_ahead:
		motion.goal_pitch = -1.0
	else:
		motion.goal_pitch = 1.0
	# Reduce rotation when close to ideal angle
	motion.goal_pitch = rotation_adjustment(PI/2 - motion.orientation_data.amt_above_below, motion.goal_pitch)


# Pitch to get target ahead
func pitch_target_ahead() -> void:
	if motion.orientation_data.target_is_above:
		motion.goal_pitch = 1.0
	else:
		motion.goal_pitch = -1.0
	# Reduce rotation when close to ideal angle
	motion.goal_pitch = rotation_adjustment(motion.orientation_data.amt_above_below, motion.goal_pitch)


# Pitch to get target behind
func pitch_target_behind() -> void:
	if motion.orientation_data.target_is_above:
		motion.goal_pitch = -1.0
	else:
		motion.goal_pitch = 1.0
	# Reduce rotation when close to ideal angle
	motion.goal_pitch = rotation_adjustment(motion.orientation_data.amt_above_below, motion.goal_pitch)


# Yaw to get target ahead
func yaw_target_ahead() -> void:
	if motion.orientation_data.target_is_right:
		motion.goal_yaw = -1.0
	else:
		motion.goal_yaw = 1.0
	# Reduce rotation when close to ideal angle
	motion.goal_yaw = rotation_adjustment(motion.orientation_data.amt_right_left, motion.goal_yaw)


# Yaw to get target behind
func yaw_target_behind() -> void:
	if motion.orientation_data.target_is_right:
		motion.goal_yaw = 1.0
	else:
		motion.goal_yaw = -1.0
	# Reduce rotation when close to ideal angle
	motion.goal_yaw = rotation_adjustment(motion.orientation_data.amt_right_left, motion.goal_yaw)


# Given an angle in radians. If that angle is less than 5 degrees,
# then reduce the turning amount by a factor of at least 2,
# more reduction as the angle difference gets closer to zero.
# This prevents oscillation when honing in on a target.
# I sure would love a better way of doing this.
func rotation_adjustment(angle_diff_rad:float, rotation_val:float) -> float:
	var angle_diff_deg:float = rad_to_deg(angle_diff_rad)
	if angle_diff_deg < 5.0:
		return rotation_val/(52.0-10*angle_diff_deg)
	else:
		return rotation_val
