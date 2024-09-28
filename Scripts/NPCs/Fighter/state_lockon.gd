extends State

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
	# Update npc and target info
	update_data()
	
	# Let's make lerp on target a function of
	# distance. Snapping to the target at long
	# range won't be as janky as snapping at
	# short range.
	var weight : float = clamp(interp_factor * dist_sqd * delta, 0.0,1.0)
	motion.new_transform = Global.interp_face_target(motion.npc, target_pos, weight)
	
	# New way
	# This code is duplicated in physics_seek_controller.gd.
	# Calculate the desired velocity, normalized and then
	# multiplied by speed.
	var desired : Vector3 = (target_pos-my_pos).normalized() * motion.npc.speed
	# Return an adjustment to velocity based on the steer force.
	motion.acceleration = (desired - motion.npc.velocity).normalized()
	
	# Slow down a little on approach to target
	motion.goal_speed = clamp(dist_sqd/speed_scaling_sqd, speed_min, 1.0)
	
	# Exit this state
	# If too close, flee away before coming in for another pass.
	if dist_sqd < too_close_sqd:
		#print('transitioning from lockon to flee')
		Transitioned.emit(self,"flee")
	# If target exited the envelope, seek.
	if envelope < z_angle:
		#print('transitioning from lockon to seek')
		Transitioned.emit(self,"seek")
