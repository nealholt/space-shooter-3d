class_name StateLoop extends State

# Fly in a big gentle loop

# This function should contain code to be
# executed at the start of the state.
func Enter() -> void:
	super.Enter()
	motion.goal_pitch = 0.5
	motion.goal_speed = 0.5


# It's mandatory that each state implement this otherwise
# abstract function, but since the motion parameters
# are set in the Enter function, there's nothing else to
# do for the loop state.
func Physics_Update(_delta:float) -> void:
	pass
