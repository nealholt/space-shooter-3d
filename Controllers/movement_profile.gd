class_name MovementProfile extends Node
# The idea here is to store information on the
# movement parameters to apply to an npc so it
# can go through preset motions such as an
# evasion sequence.

# All the states will modify this intermediate
# class and the ship will check the settings
# here on each frame and obey the given directions.
# This design was suggested in the last section of
# this video:
# https://www.youtube.com/watch?v=ow_Lum-Agbs

# My vision is that NPC script will access
# the movement profile and the state machine
# and check the movement profile each frame.

# The NPC will lerp to the given settings.
# But these are just modifiers in the range
# -1 to 1. Speed is probably 0 to 1.
var goal_speed:float # z axis speed / impulse
var goal_pitch:float
var goal_yaw:float
var goal_roll:float
var goal_strafe_x:float # x axis speed / impulse. Comparable to goal speed.
var goal_strafe_y:float # y axis speed / impulse. Comparable to goal speed.

# Add this to npc velocity
var acceleration : Vector3

# Use this to enable the NPC to indicate
# (based on getting shot) that it wants to change
# state. Evasion can't be interrupted because
# it's already evasive.
var can_interrupt_state:bool = true

func reset() -> void:
	goal_speed = 0.0
	goal_pitch = 0.0
	goal_yaw = 0.0
	goal_roll = 0.0
	goal_strafe_x = 0.0
	goal_strafe_y = 0.0
	can_interrupt_state = true
	acceleration = Vector3.ZERO


# Roll to get target above us.
func roll_target_above(orientation_data:TargetOrientationData) -> void:
	if orientation_data.target_is_right:
		goal_roll = -1.0
	else:
		goal_roll = 1.0
	# Reduce rotation when close to ideal angle
	goal_roll = rotation_adjustment(orientation_data.amt_right_left, goal_roll)


# Pitch to get target above
func pitch_target_above(orientation_data:TargetOrientationData, obstacle_detector:ObstacleDetector) -> void:
	if orientation_data.target_is_ahead:
		pitch_down(obstacle_detector)
	else:
		pitch_up(obstacle_detector)
	# Reduce pitch when close to ideal angle
	goal_pitch = rotation_adjustment(PI/2 - orientation_data.amt_above_below, goal_pitch)


# Pitch to get target ahead
func pitch_target_ahead(orientation_data:TargetOrientationData, obstacle_detector:ObstacleDetector) -> void:
	if orientation_data.target_is_above:
		pitch_up(obstacle_detector)
	else:
		pitch_down(obstacle_detector)
	# Reduce pitch when close to ideal angle
	goal_pitch = rotation_adjustment(orientation_data.amt_ahead_behind, goal_pitch)


# Pitch to get target behind
func pitch_target_behind(orientation_data:TargetOrientationData, obstacle_detector:ObstacleDetector) -> void:
	if orientation_data.target_is_above:
		pitch_down(obstacle_detector)
	else:
		pitch_up(obstacle_detector)
	# Reduce pitch when close to ideal angle
	goal_pitch = rotation_adjustment(PI-orientation_data.amt_ahead_behind, goal_pitch)


# Pitch to get target behind and ignore any collision
# detection from the whiskers. The reason this is needed
# is at close range, BOTH whiskers will detect obstacles
# suppressing pitching in BOTH directions and we don't
# want that when fleeing.
func pitch_target_behind_serious(orientation_data:TargetOrientationData) -> void:
	if orientation_data.target_is_above:
		goal_pitch = -1.0 # Pitch down
	else:
		goal_pitch = 1.0 # Pitch up
	# Reduce pitch when close to ideal angle
	goal_pitch = rotation_adjustment(PI-orientation_data.amt_ahead_behind, goal_pitch)


func pitch_up(obstacle_detector:ObstacleDetector) -> void:
	goal_pitch = 1.0
	# Deny upward pitch if the whisker indicates an obstacle
	if obstacle_detector and obstacle_detector.get_blocked_above():
		goal_pitch = 0.0

func pitch_down(obstacle_detector:ObstacleDetector) -> void:
		goal_pitch = -1.0
		# Deny downward pitch if the whisker indicates an obstacle
		if obstacle_detector and obstacle_detector.get_blocked_below():
			goal_pitch = 0.0


# Yaw to get target ahead
func yaw_target_ahead(orientation_data:TargetOrientationData) -> void:
	if orientation_data.target_is_right:
		goal_yaw = -1.0
	else:
		goal_yaw = 1.0
	# Reduce yaw when close to ideal angle
	goal_yaw = rotation_adjustment(orientation_data.amt_ahead_behind, goal_yaw)


# Yaw to get target behind
func yaw_target_behind(orientation_data:TargetOrientationData) -> void:
	if orientation_data.target_is_right:
		goal_yaw = 1.0
	else:
		goal_yaw = -1.0
	# Reduce yaw when close to ideal angle
	goal_yaw = rotation_adjustment(PI-orientation_data.amt_ahead_behind, goal_yaw)


# Given an angle in radians. If that angle is less than 5 degrees,
# then reduce the turning amount by a factor of at least 2,
# more reduction as the angle difference gets closer to zero.
# This prevents oscillation when honing in on a target.
# I sure would love a better way of doing this.
func rotation_adjustment(angle_diff_rad:float, rotation_val:float) -> float:
	var angle_diff_deg:float = rad_to_deg(angle_diff_rad)
	if angle_diff_deg < 5.0:
		# 52 on next line because angle_diff_deg < 5 means that
		# 10*angle_diff_deg < 50 which means we're dividing by
		# at least 2, dividing by more the closer angle_diff_deg
		# is to zero.
		return rotation_val/(52.0-10*angle_diff_deg)
	else:
		return rotation_val
