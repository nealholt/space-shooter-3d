extends State

# This function should contain code to be
# executed at the start of the state,
# any set up that needs performed.
func Enter() -> void:
	super.Enter()
	# Go ballistic. No "air" friction.
	motion.ballistic = true
	# Zero speed because ballistic turns off
	# friction and the extra speed makes it
	# go too fast.
	motion.goal_speed = 0.0
	# Disable interrupt
	motion.can_interrupt_state = false
	# Time for this state to run.
	# In reality it won't last this long because
	# the ship will explode and die first.
	time_limit = 60.0
	# Motion for this state
	motion.goal_pitch = random.randf_range(-1.0,1.0)
	motion.goal_roll = random.randf_range(-1.0,1.0)
