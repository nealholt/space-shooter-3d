class_name TargetOrientationData

# Global position of the thing orienting toward the target
var my_pos:Vector3
# Speed the mover is moving at
var my_speed:float
# Global position of the target
var target_pos:Vector3
# Target's velocity
var target_velocity:Vector3
# Intercept position
var intercept:Vector3
# Squared distance between the two positions
var dist_sqd:float
# Matrix of basis vectors of the thing orienting toward the target
var basis:Basis
# Angles to target in radians
var x_angle:float
var y_angle:float
var z_angle:float
# Booleans for target position relative to npc
var target_is_ahead:bool
var target_is_above:bool
var target_is_right:bool
# Magnitude in indicated direction, in radians
var amt_ahead_behind:float # zero is max ahead. pi (180) is max behind
var amt_above_below:float # zero is inbetween. pi/2 (90) is max above or below
var amt_right_left:float # zero is inbetween. pi/2 (90) is max right or left


# speed is bullet speed even if calculating a ship's intercept
# (unless the ship is intercepting for some reason other than
# shooting the target)
func update_data(pos:Vector3, speed:float, target,
				global_transform_basis:Basis) -> void:
	my_pos = pos
	my_speed = speed
	target_pos = target.global_position
	target_velocity = Vector3.ZERO
	if "velocity" in target:
		target_velocity = target.velocity
	basis = global_transform_basis
	# Calculate intercept
	var targ_vel : Vector3
	if target_velocity == Vector3.ZERO:
		intercept = target_pos
	else:
		intercept = Global.get_intercept(my_pos, my_speed, target_pos, target_velocity)
	# Calculate distance and angles relative to intercept
	dist_sqd = my_pos.distance_squared_to(intercept)
	# Calculate angles to target in radians
	y_angle = Global.get_angle_to_target(my_pos, intercept, basis.y)
	z_angle = Global.get_angle_to_target(my_pos, intercept, -basis.z)
	x_angle = Global.get_angle_to_target(my_pos, intercept, basis.x)
	# Simpler angles to target
	target_is_ahead = abs(z_angle) < PI/2
	target_is_above = abs(y_angle) < PI/2
	target_is_right = abs(x_angle) < PI/2
	# Get magnitude in the direction in radians
	amt_ahead_behind = z_angle # 0 is dead ahead. pi is directly behind
	amt_above_below = abs(PI/2 - abs(y_angle)) # pi/2 is directly above or below. 0 is inbetween
	amt_right_left = abs(PI/2 - abs(x_angle)) # pi/2 is directly right or left. 0 is inbetween


func get_data_string() -> String:
	var temp_str:String = "\ntarget:\n"
	if target_is_above:
		temp_str += "above %0.2f degrees %0.2f\n" % [(90-rad_to_deg(y_angle)),rad_to_deg(amt_above_below)]
	else:
		temp_str += "below %0.2f degrees %0.2f\n" % [(rad_to_deg(y_angle)-90),rad_to_deg(amt_above_below)]
	if target_is_right:
		temp_str += "right %0.2f degrees %0.2f\n" % [(90-rad_to_deg(x_angle)),rad_to_deg(amt_right_left)]
	else:
		temp_str += "left %0.2f degrees %0.2f\n" % [(rad_to_deg(x_angle)-90),rad_to_deg(amt_right_left)]
	if target_is_ahead:
		temp_str += "ahead"
	else:
		temp_str += "behind"
	temp_str += " %0.2f\n" % rad_to_deg(z_angle)
	temp_str += "At distance %d" % round(sqrt(dist_sqd))
	return temp_str
