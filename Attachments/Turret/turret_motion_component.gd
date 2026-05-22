class_name TurretMotionComponent extends Node

# Pass the body to be rotated to the function below
# ala this tutorial at about 5:30:
# https://www.youtube.com/watch?v=EMpXt2MLx_4

# movement speeds and constraints in radians
var elevation_speed:float
var rotation_speed:float
var min_elevation:float
var max_elevation:float

# ROTATION_LIMIT_DEG is only used for manual "head turning"
const ROTATION_LIMIT_DEG:float = 60 # 60 degrees


func setup_values(dat:TurretData) -> void:
	elevation_speed = deg_to_rad(dat.elevation_speed_deg)
	rotation_speed = deg_to_rad(dat.rotation_speed_deg)
	min_elevation = deg_to_rad(dat.min_elevation_deg)
	max_elevation = deg_to_rad(dat.max_elevation_deg)

# The following is loosely based on code from here:
# https://github.com/IndieQuest/ModularTurret/tree/master/src
# https://www.youtube.com/watch?v=4IS9zIVCDKc&ab_channel=IndieQuest
# but modified by Neal Holtschulte in 2024 because
# 1. That code didn't work for me and 
# 2. it was designed to only work when the turret
# was parallel to the ground.
# This was a life saver:
# https://math.stackexchange.com/questions/728481/3d-projection-onto-a-plane
func rotate_and_elevate(body:Node3D, head:Node3D, delta:float, current_target:Vector3) -> void:
	# Project the target onto the XZ plane of the turret
	# but first adjust by the global position because
	# the global basis is purely orientation, not position.
	var rotation_targ:Vector3 = get_projected(current_target - body.global_position, body.global_basis.y)
	# But! You also need to account for changes in position,
	# so add back in the global position adjustment.
	rotation_targ = rotation_targ + body.global_position

	# Get the angle from the body's facing direction (z)
	# to the projected point. Since the point is projected
	# onto the plane, this should be the angle the body
	# should rotate to face along only one axis.
	var y_angle:float = Global.get_angle_to_target(body.global_position, rotation_targ, body.global_basis.z)
	
	# Rotate toward target
	# Calculate sign to rotate left or right.
	var rotation_sign:float = sign(body.to_local(current_target).x)
	# Calculate step size and direction. Use min to avoid
	# over-rotating. Just snap to the desired angle if it's
	# less than what we would rotate this frame.
	var final_y:float = rotation_sign * min(rotation_speed * delta, y_angle)
	body.rotate_y(final_y)
	
	# Rotation is complete, now we elevate.
	# Project the target onto the ZY plane of the head
	# but first adjust by the global position because
	# the global basis is purely orientation, not position.
	var elevation_targ:Vector3 = get_projected(current_target - head.global_position, head.global_basis.x)
	# But! You also need to account for changes in position,
	# so add back in the global position adjustment.
	elevation_targ = elevation_targ + head.global_position
	
	# Get the angle from the head's facing direction (z)
	# to the projected point. Since the point is projected
	# onto the plane, this should be the angle the head
	# should rotate to face along only one axis.
	var x_angle:float = Global.get_angle_to_target(head.global_position, elevation_targ, head.global_basis.z)
	
	# Elevate toward target.
	# Calculate sign to elevate up or down.
	# There's an extra negative sign because pitching up is negative.
	var elevation_sign:float = -sign(head.to_local(current_target).y)
	# Calculate step size and direction. Use min to avoid
	# over-rotating. Just snap to the desired angle if it's
	# less than what we would rotate this frame.
	var final_x:float = elevation_sign * min(elevation_speed * delta, x_angle)
	head.rotate_x(final_x)
	# Clamp elevation within limits.
	# Swap and negate max and min because up is negative and
	# down is positive.
	head.rotation.x = clamp(
		head.rotation.x,
		-max_elevation, -min_elevation
	)


# Just like the above function, but lerps to goal rotations by delta
func rotate_and_elevate_lerp(body:Node3D, head:Node3D, delta:float, current_target:Vector3) -> void:
	# Project the target onto the XZ plane of the turret
	# but first adjust by the global position because
	# the global basis is purely orientation, not position.
	var rotation_targ:Vector3 = get_projected(current_target - body.global_position, body.global_basis.y)
	# But! You also need to account for changes in position,
	# so add back in the global position adjustment.
	rotation_targ = rotation_targ + body.global_position

	# Get the angle from the body's facing direction (z)
	# to the projected point. Since the point is projected
	# onto the plane, this should be the angle the body
	# should rotate to face along only one axis.
	var y_angle:float = Global.get_angle_to_target(body.global_position, rotation_targ, body.global_basis.z)
	# Calculate sign to rotate left or right.
	var rotation_sign:float = sign(body.to_local(current_target).x)
	
	# Goal is to change body.rotation.y by y_angle in
	# the direction of rotation_sign.
	# Lerp toward goal angle
	body.rotation.y = lerp(body.rotation.y, body.rotation.y+rotation_sign*y_angle, delta)
	# Clamp rotation within limits.
	body.rotation.y = clamp(
		body.rotation.y,
		-PI, PI
	)
	#print()
	#print('y_angle ', rad_to_deg(y_angle))
	#print('rotation_sign ', rotation_sign)
	#print('body.rotation.y ', rad_to_deg(body.rotation.y))
	
	
	# Rotation is complete, now we elevate.
	# Project the target onto the ZY plane of the head
	# but first adjust by the global position because
	# the global basis is purely orientation, not position.
	var elevation_targ:Vector3 = get_projected(current_target - head.global_position, head.global_basis.x)
	# But! You also need to account for changes in position,
	# so add back in the global position adjustment.
	elevation_targ = elevation_targ + head.global_position
	
	# Get the angle from the head's facing direction (z)
	# to the projected point. Since the point is projected
	# onto the plane, this should be the angle the head
	# should rotate to face along only one axis.
	var x_angle:float = Global.get_angle_to_target(head.global_position, elevation_targ, head.global_basis.z)
	
	# The following is consistent with how rotation is
	# calculated above.
	# There's an extra negative sign because pitching up is negative.
	var elevation_sign:float = -sign(head.to_local(current_target).y)
	# Lerp toward goal angle
	head.rotation.x = lerp(head.rotation.x, head.rotation.x+elevation_sign*x_angle, delta)
	
	# The following is INCONSISTENT with how rotation is
	# calculated above, but weirdly also seems to work?!
	#head.rotation.x = lerp(head.rotation.x, x_angle, delta)
	
	# Clamp elevation within limits.
	# Swap and negate max and min because up is negative and
	# down is positive.
	head.rotation.x = clamp(
		head.rotation.x,
		-max_elevation, -min_elevation
	)


func get_projected(pos:Vector3, normal:Vector3) -> Vector3:
	# Project position "pos" onto the plane with the given normal vector.
	# https://math.stackexchange.com/questions/728481/3d-projection-onto-a-plane
	# "projected" is the vector indicating how far above/below
	# the target is from the plane of rotation.
	normal = normal.normalized()
	var projection:Vector3 = (pos.dot(normal) / normal.dot(normal)) * normal
	# By subtracting projection from position, we get the
	# projected point.
	return pos - projection


# Rotate the given body around the y axis toward the goal percent rotation
func swivel_toward(body:Node3D, rotation_percent:float, delta:float) -> void:
	if rotation_percent==0.0:
		return
	# Calculate sign to rotate left or right.
	var rotation_sign:float = sign(rotation_percent)
	# Because straight ahead is both 180 and -180, the following if else
	# is needed to not have lerp take the long way around the circle.
	# For instance 170 and -170 are only 20 degrees apart, but if you
	# try to lerp from 170 to -170, it goes 160, 150, 140 ...
	# instead of 170, 180, -170.
	if rotation_percent < 0: # Right
		if body.rotation_degrees.y < 0:
			body.rotation_degrees.y += 360
	else: # Left
		if 0 < body.rotation_degrees.y:
			body.rotation_degrees.y -= 360
	# Lerp by delta toward the goal angle
	var goal_angle:float = -rotation_sign*180+rotation_percent*ROTATION_LIMIT_DEG
	body.rotation_degrees.y = lerp(body.rotation_degrees.y, goal_angle, delta)


# Rotate the given body(head) around the x axis toward the goal
# percent rotation
func pitch_toward(head:Node3D, rotation_percent:float, delta:float) -> void:
	if rotation_percent==0.0:
		return
	# Get goal angle
	var goal_angle:float = -rotation_percent*rad_to_deg(max_elevation)
	# Lerp by delta toward the goal angle
	head.rotation_degrees.x = lerp(head.rotation_degrees.x, goal_angle, delta)
