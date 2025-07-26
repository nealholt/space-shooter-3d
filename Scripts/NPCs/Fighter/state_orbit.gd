extends State
# Orbital strafing behavior.
# Only capital ships do this for now.

# Ideal attack distance squared
var ideal_distance_sqd := 450.0**2 # Squared for efficiency
# Distance at which to reduce speed as we ease toward
# ideal attack distance
var ease_dist_sqd := 200.0**2 # Squared for efficiency

# This function should be called on each
# physics update frame.
func Physics_Update(delta:float) -> void:
	# Pitch and yaw toward target.
	pitch_target_ahead()
	yaw_target_ahead()
	
	# Set speed based on distance to target to ease
	# into the ideal attack distance
	var diff := motion.orientation_data.dist_sqd - ideal_distance_sqd
	motion.goal_speed = clamp(diff/ease_dist_sqd, -1.0, 1.0)
