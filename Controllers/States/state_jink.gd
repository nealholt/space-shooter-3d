class_name StateJink extends State
# Transition to this state with a random chance when taking fire.
# Switch back and forth between periods of pitching up and down.
# With a short roll thrown in for good measure

# The jink behavior resets up to jink_limit_max times.
var jink_count := 0
var jink_limit := 0
var jink_limit_min := 0
var jink_limit_max := 4

# A single jink behavior lasts between these intervals
var min_jink_duration := 1.5 # seconds
var max_jink_duration := 4.0 # seconds

# Each jink starts with a shorter duration of roll
var min_roll_duration := 0.0 # seconds
var max_roll_duration := 2.0 # seconds
var roll_duration : float # seconds


var min_speed := 0.7
var max_speed := 1.0

# This function should contain code to be
# executed at the start of the state,
# including any set up that needs performed.
func Enter(motion:MovementProfile) -> void:
	super.Enter(motion) # This resets elapsed_time to zero
	# Set speed
	motion.goal_speed = random.randf_range(min_speed,max_speed)
	# Disable interrupt
	motion.can_interrupt_state = false
	# Duration of the first jink
	time_limit = random.randf_range(min_jink_duration,max_jink_duration)
	# Motion for this state. Start with pitch up or down
	motion.goal_pitch = _one_or_neg_one()
	# Start with a shorter roll left or right
	motion.goal_roll = _one_or_neg_one()
	roll_duration = random.randf_range(min_roll_duration,max_roll_duration)
	# Select maximum number of distinct jinks
	jink_limit = random.randi()%(jink_limit_max-jink_limit_min) + jink_limit_min
	jink_count = 0 # Reset
	#print()
	#print(time_limit)
	#print(jink_limit)
	#print(elapsed_time)


# This function should be called on each
# physics update frame.
func Physics_Update(delta:float, motion:MovementProfile, _orientation_data:TargetOrientationData) -> void:
	# Keep the current motion settings for a limited
	# duration before switching to different settings
	elapsed_time += delta
	if elapsed_time < time_limit:
		return
	
	# Transition out of this state after a limited number of jinks.
	if jink_count >= jink_limit:
		Transitioned.emit(self,'attack')
		return
	
	# Each subsequent jink switches pitch and rerandomizes roll
	motion.goal_pitch *= -1.0 # Negate pitch
	# Rerandomize roll
	motion.goal_roll = _one_or_neg_one()
	roll_duration = random.randf_range(min_roll_duration,max_roll_duration)
	# Rerandomize speed
	motion.goal_speed = random.randf_range(min_speed,max_speed)
	# Proceed to next jink
	jink_count += 1
	#print('proceeding to jink ',jink_count)
	# Reset jink time limit
	time_limit = random.randf_range(min_jink_duration,max_jink_duration)
	elapsed_time = 0.0
