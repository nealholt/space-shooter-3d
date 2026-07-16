class_name StateAttack extends State
# if distance to target is too close,
#     transition into flee state
# else if facing target and line of sight to target is blocked,
#     then call "steer around" which will give a waypoint,
#     which will transition into the Go to state.
# otherwise steer to face target and attack


# Distance at which to peel off, flee, before
# coming back around for another pass.
# This value is over-written by the npc_controller
var too_close_sqd := 0.0

# This function should contain code to be
# executed at the start of the state,
# including any set up that needs performed.
func Enter() -> void:
	super.Enter()
	motion.goal_speed = 1.0 # Top speed

# This function should be called on each
# physics update frame.
func Physics_Update(_delta:float) -> void:
	# Transition to avoid if blocked ahead
	if obstacle_detector and obstacle_detector.get_blocked_ahead():
		Transitioned.emit(self,'avoid')
	# If distance to target is too close,
	#     transition into flee state
	elif motion.orientation_data.dist_sqd < too_close_sqd:
		#print('transitioning from seek to flee')
		Transitioned.emit(self,'flee')
	# else if facing target and line of sight to target is blocked,
	#     then call "steer around" which will set an intermediate
	#     waypoint and transition into the GoTo state.
	elif motion.orientation_data.target_is_ahead and !RayOnDemand.me.line_is_clear(motion.orientation_data.my_pos, motion.orientation_data.target_pos, motion.orientation_data.target.get_parent()):
		steer_around()
	# otherwise steer to face target and attack
	else:
		# Roll to get target above us.
		roll_target_above()
		# Pitch toward target.
		pitch_target_ahead()
		# Yaw to get target ahead
		yaw_target_ahead()


func steer_around() -> void:
	# Get a more convenient variable for my position
	var my_pos := motion.orientation_data.my_pos
	# Get my target's body. Ignore raycast collisions with this
	var target_body:Node3D = motion.orientation_data.target.get_parent()
	# Get the point in space midway between self and target
	var midpoint:Vector3 = my_pos + (motion.orientation_data.target_pos - my_pos)/2
	# Move the point up or down until a clear space is reached
	# or all the adjustments have been exhausted.
	var adjustments := [20,-20,50,-50,100,-100,200,-200,500,-500]
	var up:Vector3 = motion.orientation_data.basis.y
	var new_point:Vector3
	for adjustment in adjustments:
		new_point = midpoint + up*adjustment
		# Verify that there is a clear path to new_point.
		# If so, transition to goto on the new position
		if RayOnDemand.me.line_is_clear(my_pos, new_point, target_body):
			# TODO LEFT OFF HERE TODO TESTING
			print(adjustment,' is clear, going to intermediate point')
			motion.orientation_data.intermediate_pos = new_point
			Transitioned.emit(self,'goto')
			return
		# otherwise keep looping.
	# No ability to steer around was detected, just pitch up
	# or down hard with no other movement.
	# But if you already were pitching, just keep at it.
	motion.goal_roll = 0.0
	motion.goal_yaw = 0.0
	if abs(motion.goal_pitch) != 1.0:
		# TODO LEFT OFF HERE TODO TESTING
		print('Totally blocked. Pitching to the max')
		motion.goal_pitch = [-1.0, 1.0].pick_random()
