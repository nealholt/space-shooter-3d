class_name TurretMotionComponent extends Node

# Pass the body to be rotated to the function below
# ala this tutorial at about 5:30:
# https://www.youtube.com/watch?v=EMpXt2MLx_4

# movement speeds and constraints in radians
var elevation_speed:float
var rotation_speed:float
var min_elevation:float
var max_elevation:float

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
	# Reverse and negate max and min because up is negative and
	# down is positive.
	head.rotation.x = clamp(
		head.rotation.x,
		-max_elevation, min_elevation
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
