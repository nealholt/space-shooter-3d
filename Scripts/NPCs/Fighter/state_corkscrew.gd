extends State
# Transition to this state with a random chance when taking fire.


# This function should contain code to be
# executed at the start of the state,
# any set up that needs performed.
func Enter() -> void:
	super.Enter()
	# Set highest speed
	motion.goal_speed = 1.0
	# Disable interrupt
	motion.can_interrupt_state = false
	# Time for this state to run
	time_limit = 8.0
	# Motion for this state
	if random.randi()%2 == 0:
		motion.goal_pitch = 1.0
	else:
		motion.goal_pitch = -1.0
	if random.randi()%2 == 0:
		motion.goal_roll = 1.0
	else:
		motion.goal_roll = -1.0


# This function should be called on each
# physics update frame.
func Physics_Update(delta:float) -> void:
	elapsed_time += delta
	if elapsed_time > time_limit:
		Transitioned.emit(self,"seek")
