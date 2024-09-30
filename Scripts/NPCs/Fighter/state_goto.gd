extends State

var destination:Vector3 = Vector3.ZERO
var too_close_sqd := 1000.0**2 # Squared for efficiency


# This function should contain code to be
# executed at the start of the state,
# any set up that needs performed.
func Enter() -> void:
	super.Enter()
	# Set  speed
	motion.goal_speed = 1.0


# This function should be called on each
# physics update frame.
func Physics_Update(delta:float) -> void:
	# Interp to face destination
	motion.new_transform = Global.interp_face_target(motion.npc, destination, delta)
	# Exit this state
	var dist := motion.npc.global_position.distance_squared_to(destination)
	# If too close
	if dist < too_close_sqd:
		Transitioned.emit(self,"seek")
