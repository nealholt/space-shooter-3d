class_name StateOrbit extends State
# Orbital strafing behavior.
# Only capital ships do this for now.

var keep_target_above:bool = false # Whether to orient so target is ahead (default) or above

# Ideal attack distance squared
var ideal_distance_sqd := 450.0**2 # Squared for efficiency
# Distance at which to reduce speed as we ease toward
# ideal attack distance
var ease_dist_sqd := 300.0**2 # Squared for efficiency


func Enter(motion:MovementProfile) -> void:
	super.Enter(motion)
	# Disable interrupt
	motion.can_interrupt_state = false


# This function should be called on each
# physics update frame.
func Physics_Update(_delta:float, motion:MovementProfile, orientation_data:TargetOrientationData) -> void:
	var diff := orientation_data.dist_sqd - ideal_distance_sqd
	# Seek target if too far away
	if orientation_data.dist_sqd > ideal_distance_sqd + ease_dist_sqd:
		motion.pitch_target_ahead(orientation_data, obstacle_detector)
		motion.yaw_target_ahead(orientation_data)
		motion.goal_speed = 1.0
		motion.goal_strafe_y = 0.0 # Reset
		motion.goal_strafe_x = 0.0 # Reset
	else:
		if keep_target_above:
			# Pitch and roll to put target above
			motion.roll_target_above(orientation_data)
			motion.pitch_target_above(orientation_data, obstacle_detector)
			# Give the y axis (up/down) a little tweak to seek
			# ideal distance
			motion.goal_strafe_y = (orientation_data.dist_sqd - ideal_distance_sqd) / ease_dist_sqd
			# Maintain full speed
			motion.goal_speed = 1.0
			# Small random yaw
			motion.goal_strafe_x = clamp(motion.goal_strafe_x+randf_range(-0.1,0.1), -1.0, 1.0)
		else:
			# Pitch and yaw to face target.
			motion.pitch_target_ahead(orientation_data, obstacle_detector)
			motion.yaw_target_ahead(orientation_data)
			# Set speed based on distance to target to ease
			# into the ideal attack distance
			if orientation_data.target_is_ahead:
				motion.goal_speed = clamp(diff/ease_dist_sqd, -1.0, 1.0)
			else:
				motion.goal_speed = clamp(-diff/ease_dist_sqd, -1.0, 1.0)
			# Small random strafe around
			motion.goal_strafe_y = clamp(motion.goal_strafe_y+randf_range(-0.1,0.1), -1.0, 1.0)
			motion.goal_strafe_x = clamp(motion.goal_strafe_x+randf_range(-0.1,0.1), -1.0, 1.0)


# No death animation for now
func enter_death_animation() -> void:
	pass
