extends State
# Transition to this state with a random chance when taking fire.

var wave_count := 0
var wave_limit := 0
var wave_limit_min := 1
var wave_limit_max := 6

var minimum_wave_duration := 1.0 # seconds
var maximum_wave_duration := 3.0 # seconds

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
	time_limit = random.randf_range(minimum_wave_duration,maximum_wave_duration)
	# Motion for this state
	if random.randi()%2 == 0:
		motion.goal_pitch = 1.0
	else:
		motion.goal_pitch = -1.0
	# Select maximum number of waves
	wave_limit = random.randi()%(wave_limit_max-wave_limit_min) + wave_limit_min


# This function should be called on each
# physics update frame.
func Physics_Update(delta:float) -> void:
	elapsed_time += delta
	if elapsed_time > time_limit:
		# Transition out of this state after a limited number of waves.
		if wave_count == wave_limit:
			Transitioned.emit(self,"seek")
		else:
			wave_count += 1
			# Pitch the other direction and reset timer
			motion.goal_pitch = motion.goal_pitch*-1.0
			time_limit = random.randf_range(minimum_wave_duration,maximum_wave_duration)
