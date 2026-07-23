class_name StateCorkscrew extends State
# Transition to this state with a random chance when taking fire.

var min_duration := 3.5 # seconds
var max_duration := 8.0 # seconds


# This function should contain code to be
# executed at the start of the state,
# including any set up that needs performed.
func Enter(motion:MovementProfile) -> void:
	super.Enter(motion)
	# Set highest speed
	motion.goal_speed = 1.0
	# Disable interrupt
	motion.can_interrupt_state = false
	# Time for this state to run
	time_limit = random.randf_range(min_duration,max_duration)
	# Motion for this state
	motion.goal_pitch = _one_or_neg_one()
	motion.goal_roll = _one_or_neg_one()


# This function should be called on each
# physics update frame.
func Physics_Update(delta:float, _motion:MovementProfile, _orientation_data:TargetOrientationData) -> void:
	elapsed_time += delta
	if elapsed_time > time_limit:
		Transitioned.emit(self,'attack')
