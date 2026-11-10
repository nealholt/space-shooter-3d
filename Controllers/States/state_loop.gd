class_name StateLoop extends State

# Fly in a big gentle loop until a target appears

# This function should contain code to be
# executed at the start of the state.
func Enter(motion:MovementProfile) -> void:
	super.Enter(motion)
	motion.goal_pitch = 0.15
	motion.goal_speed = 0.5


# It's mandatory that each state implement this otherwise
# abstract function, but since the motion parameters
# are set in the Enter function, there's nothing else to
# do for the loop state.
func Physics_Update(_delta:float, _motion:MovementProfile, orientation_data:TargetOrientationData) -> void:
	# Force a target update to see if there's a target
	NewTargetRequested.emit()
	if orientation_data.has_target():
		Transitioned.emit(self,'attack')
