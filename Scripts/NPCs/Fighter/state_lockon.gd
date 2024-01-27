extends State

#TODO weapons free flag not implemented, might not be wanted
# Interpolate on target lead location and set
# weapons free. Gradually increase interpolate
# weight over the course of X seconds from 0 to 1.
# If within too_close distance to target,
# enter a flee state.
# If target leaves threshold angle before
# interpolation (as might occur with gap drive),
# enter seek state.

# Within this range, transition to a flee state
var too_close_sqd:float = 25.0**2 # meters

# If target leaves this angle margin then
# transition into seek state. The number is in
# degrees, immediately converted to radians
var envelope:float = deg_to_rad(15)

# Factor for scaling interpolation. The higher
# this number, the more rapidly we snap to target.
var interp_factor := 0.5

# Parameters for scaling speed with distance to target
var speed_min := 0.35
var speed_scaling_sqd := 250.0**2 # Squared to keep consistent with distance

# This function should contain code to be
# executed at the start of the state,
# any set up that needs performed.
func Enter() -> void:
	motion.reset()
	# Set intermediate speed
	motion.goal_speed = 0.5

# This function should be called on each
# physics update frame.
func Physics_Update(delta:float) -> void:
	# Get npc and target info
	var my_pos:Vector3 = motion.npc.global_position
	var pos:Vector3 = motion.npc.target_pos
	var dist_sqd:float = motion.npc.distance_to_target_sqd
	var basis = motion.npc.global_transform.basis

	# Let's make lerp on target a function of
	# distance. Snapping to the target at long
	# range won't be as janky as snapping at
	# short range.
	var weight : float = clamp(interp_factor * dist_sqd * delta, 0.0,1.0)
	motion.new_transform = Global.interp_face_target(motion.npc, pos, weight)
	
	# Slow down a little on approach to target
	motion.goal_speed = clamp(dist_sqd/speed_scaling_sqd, speed_min, 1.0)
	
	# Exit this state
	# If too close, flee away before coming in for another pass.
	if dist_sqd < too_close_sqd:
		#print('transitioning from lockon to flee')
		Transitioned.emit(self,"flee")
	var z_angle:float = Global.get_angle_to_target(my_pos, pos, -basis.z)
	# If target exited the envelope, seek.
	if envelope < z_angle:
		#print('transitioning from lockon to seek')
		Transitioned.emit(self,"seek")
