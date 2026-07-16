class_name StateAttack extends State
# if distance to target is too close,
#     transition into flee state
# else if facing target and line of sight to target is blocked,
#     then call "steer around" which will give a waypoint,
#     which will transition into the Go to state.
# otherwise steer to face target and attack


@onready var ray: RayCast3D = $RayCast3D

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
	# If distance to target is too close,
	#     transition into flee state
	if motion.orientation_data.dist_sqd < too_close_sqd:
		#print('transitioning from seek to flee')
		Transitioned.emit(self,"flee")
		return
	# else if facing target and line of sight to target is blocked,
	#     then call "steer around" which will give a waypoint,
	#     which will transition into the Go to state.
	elif motion.orientation_data.target_is_ahead and obstacle_to_target():
		pass # TODO LEFT OFF HERE
	# otherwise steer to face target and attack
	else:
		# Roll to get target above us.
		roll_target_above()
		# Pitch toward target.
		pitch_target_ahead()
		# Yaw to get target ahead
		yaw_target_ahead()


# The following is VERY similar to code in massive_explosion
# Returns true if there is an obstacle between ship and its target.
func obstacle_to_target() -> bool:
	return false
	#print() # TODO TESTING
	#print(my_pos)
	#print(target_pos)
	# Position ray from me to my target
	ray.position = my_pos
	ray.target_position = target_pos - my_pos
	# Force an update
	ray.force_raycast_update()
	# Is there a collision?
	if ray.is_colliding():
		#print(ray.get_collider()) # TODO TESTING
		return true
	# Clear view of explosion
	return false
