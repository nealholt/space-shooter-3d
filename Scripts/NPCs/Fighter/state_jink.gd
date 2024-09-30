extends State
# Transition to this state with a random chance when taking fire.
# Switch back and forth between rolling and pitching.

var jink_count := 0
var jink_limit := 0
var jink_limit_min := 1
var jink_limit_max := 6

var min_jink_duration := 0.5 # seconds
var max_jink_duration := 3.5 # seconds

var currently_rolling:bool = true

var min_speed := 0.5
var max_speed := 1.0

# This function should contain code to be
# executed at the start of the state,
# any set up that needs performed.
func Enter() -> void:
	super.Enter()
	# Set  speed
	motion.goal_speed = random.randf_range(min_speed,max_speed)
	# Disable interrupt
	motion.can_interrupt_state = false
	# Time for this state to run
	time_limit = random.randf_range(min_jink_duration,max_jink_duration)
	# Motion for this state
	if random.randi()%2 == 0:
		motion.goal_roll = 1.0
	else:
		motion.goal_roll = -1.0
	# Select maximum number of waves
	jink_limit = random.randi()%(jink_limit_max-jink_limit_min) + jink_limit_min


# This function should be called on each
# physics update frame.
func Physics_Update(delta:float) -> void:
	elapsed_time += delta
	if elapsed_time > time_limit:
		# Transition out of this state after a limited number of waves.
		if jink_count == jink_limit:
			Transitioned.emit(self,"seek")
		else:
			# Reset speed
			motion.goal_speed = random.randf_range(min_speed,max_speed)
			# Switch between roll and pitch
			if currently_rolling:
				# Switch to pitch
				motion.goal_roll = 0.0
				if random.randi()%2 == 0:
					motion.goal_pitch = 1.0
				else:
					motion.goal_pitch = -1.0
			else:
				jink_count += 1
				# Switch to roll
				motion.goal_pitch = 0.0
				if random.randi()%2 == 0:
					motion.goal_roll = 1.0
				else:
					motion.goal_roll = -1.0
			currently_rolling = !currently_rolling
			# Reset jink time limit
			time_limit = random.randf_range(min_jink_duration,max_jink_duration)
