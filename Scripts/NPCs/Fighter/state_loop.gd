extends State

# Fly in a big gentle loop

# This function should contain code to be
# executed at the start of the state,
# any set up that needs performed.
func Enter() -> void:
	super.Enter()
	motion.goal_pitch = 0.5
	motion.goal_speed = 0.5
