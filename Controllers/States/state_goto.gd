class_name StateGoto extends State
# Go to a point in space. The point is
# motion.orientation_data.intermediate_pos which is a bit hacky
# but it works well enough.

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
	# Reset orientation data on the position we are
	# going to, not the target.
	motion.orientation_data.reset_on_intermediate()
	# If distance to target is too close,
	#     transition into attack state
	if motion.orientation_data.dist_sqd < too_close_sqd:
		Transitioned.emit(self,"attack")
	# otherwise steer to face target
	else:
		# Roll to get target above us.
		roll_target_above()
		# Pitch toward target.
		pitch_target_ahead()
		# Yaw to get target ahead
		yaw_target_ahead()
