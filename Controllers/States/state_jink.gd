class_name StateJink extends State
# Transition to this state with a random chance when taking fire.
# Switch back and forth between rolling and pitching.

# The jink behavior resets up to jink_limit_max times.
var jink_count := 0
var jink_limit := 0
var jink_limit_min := 0
var jink_limit_max := 4

# A single jink behavior lasts between these intervals
var min_jink_duration := 0.5 # seconds
var max_jink_duration := 2.0 # seconds

# Switch between intervals of pitching and intervals
# of rolling. Start with pitch.
var currently_rolling:bool = false

var min_speed := 0.7
var max_speed := 1.0

# This function should contain code to be
# executed at the start of the state,
# including any set up that needs performed.
func Enter(motion:MovementProfile) -> void:
	super.Enter(motion) # This resets elapsed_time to zero
	# Set  speed
	motion.goal_speed = random.randf_range(min_speed,max_speed)
	# Disable interrupt
	motion.can_interrupt_state = false
	# Duration of this state
	time_limit = random.randf_range(min_jink_duration,max_jink_duration)
	# Motion for this state. Start with pitch up or down
	if random.randi()%2 == 0:
		motion.goal_pitch = 1.0
	else:
		motion.goal_pitch = -1.0
	# Select maximum number of distinct jinks
	jink_limit = random.randi()%(jink_limit_max-jink_limit_min) + jink_limit_min


# This function should be called on each
# physics update frame.
func Physics_Update(delta:float, motion:MovementProfile, _orientation_data:TargetOrientationData) -> void:
	# Keep the current motion settings for a limited
	# duration before switching to different settings
	elapsed_time += delta
	if elapsed_time < time_limit:
		return
	# Transition out of this state after a limited number of waves.
	if jink_count >= jink_limit:
		Transitioned.emit(self,'attack')
	else:
		# Each subsequent jink switches between roll
		# and pitch
		if currently_rolling:
			# Switch to pitch
			motion.goal_roll = 0.0
			if random.randi()%2 == 0:
				motion.goal_pitch = 1.0
			else:
				motion.goal_pitch = -1.0
			# Random speed
			motion.goal_speed = random.randf_range(min_speed,max_speed)
		else:
			# Switch to roll
			motion.goal_pitch = 0.0
			if random.randi()%2 == 0:
				motion.goal_roll = 1.0
			else:
				motion.goal_roll = -1.0
			# Roll at max speed
			motion.goal_speed = max_speed
		
		jink_count += 1
		currently_rolling = !currently_rolling
		# Reset jink time limit
		time_limit = random.randf_range(min_jink_duration,max_jink_duration)
