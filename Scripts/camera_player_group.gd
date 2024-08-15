extends Node3D

# https://www.reddit.com/r/godot/comments/18w6prn/camera_considerations/

enum CameraState {FIRSTPERSON, REAR, FLYBY, TARGETCLOSEUP, TARGETVIEW}
var state = CameraState.FIRSTPERSON

# free_camera has top_level set to true. Other cameras
# are children of the player.
#@onready var first_person_camera: Camera3D = $FirstPersonCamera
@onready var first_person_camera: Camera3D = $Body/Head/FirstPersonCamera
@onready var rear_under_camera: Camera3D = $RearUnderCamera
@onready var free_camera: Camera3D = $FreeCamera

var rng = RandomNumberGenerator.new() # For positioning flyby camera

var target:Node3D

const target_close_up_dist:=-30.0

var look_at_target : bool = false
@export var look_speed : float = 59.0

func _physics_process(delta: float) -> void:
	if state == CameraState.FLYBY:
		free_camera.look_at(global_position, Vector3.UP)
	elif state == CameraState.TARGETCLOSEUP:
		if is_instance_valid(target):
			view_target_close()
		else:
			first_person()
	elif state == CameraState.TARGETVIEW:
		if is_instance_valid(target):
			view_target_from_player()
		else:
			first_person()
	# Look at target with first-person cam
	if look_at_target and state == CameraState.FIRSTPERSON and is_instance_valid(target):
		rotate_and_elevate(delta, $Body, $Body/Head, target.global_position)
		#first_person_camera.look_at(target.global_position, Global.player.global_transform.basis.y)
		
		# Here's where I tried it using the code copied from 
		# Global.interp_face_target. Doesn't work.
		#var new_transform = first_person_camera.transform.looking_at(target.global_position,first_person_camera.global_transform.basis.y)
		#first_person_camera.transform = first_person_camera.transform.interpolate_with(new_transform, delta*look_speed)
		
		#first_person_camera.rotation = lerp(first_person_camera.rotation, first_person_camera.get_angle_to(target.global_position),look_speed)
		#first_person_camera.rotation = lerp_angle(from, to, weight)
		#first_person_camera.rotation.y=lerp_angle(first_person_camera.rotation.y,atan2(target.global_position.x,target.global_position.z),look_speed*delta)
		#first_person_camera.rotation.z=lerp(first_person_camera.rotation.z,atan2(-target.global_position.x,-target.global_position.y),look_speed*delta)
		#first_person_camera.rotation.x=lerp(first_person_camera.rotation.x,atan2(-target.global_position.y,-target.global_position.z),look_speed*delta)
		#print(first_person_camera.global_position.direction_to(target.global_position))
		#first_person_camera.global_transform.basis.z = lerp(first_person_camera.global_transform.basis.z, -first_person_camera.global_position.direction_to(target.global_position), look_speed*delta)
		#first_person_camera.global_transform.basis.z = lerp(first_person_camera.global_transform.basis.z, -first_person_camera.get_angle_to(target.global_position), look_speed*delta)
		#first_person_camera.transform = Global.interp_face_target(first_person_camera, target.global_position, look_speed*delta)
		
	else:
		# Return to facing forward, or at least way far
		# forward of the nose of the player.
		# TODO fix this next bit and just have a Node3D attached to the player straight ahead
		var temp_targ_pos : Vector3 = first_person_camera.global_position - Global.player.global_transform.basis.z*10000.0
		rotate_and_elevate(delta, $Body, $Body/Head, temp_targ_pos)
		#first_person_camera.look_at(first_person_camera.global_position - Global.player.global_transform.basis.z*10000.0, Global.player.global_transform.basis.y)
		
		# Here's where I tried it using the code copied from 
		# Global.interp_face_target but with the player's up
		# as the "look"s up. Doesn't work.
		#var new_transform = first_person_camera.transform.looking_at(first_person_camera.global_position - Global.player.global_transform.basis.z*10000.0, Global.player.global_transform.basis.y)
		#first_person_camera.transform = first_person_camera.transform.interpolate_with(new_transform, delta*look_speed)
		
		#first_person_camera.transform = Global.interp_face_target(first_person_camera, first_person_camera.global_position - Global.player.global_transform.basis.z*10000.0, look_speed*delta)
		#var new_transform = first_person_camera.transform.looking_at(first_person_camera.global_position - Global.player.global_transform.basis.z*10000.0, Global.player.global_transform.basis.y)
		#first_person_camera.transform = first_person_camera.transform.interpolate_with(new_transform, look_speed*delta)



# The following is duplicated in turret.gd
# I was trying to smooth out target look, but
# this didn't work.
func rotate_and_elevate(delta: float, body:Node3D, head:Node3D, current_target:Vector3) -> void:
	var rotation_speed : float = 3.0
	var elevation_speed : float = 3.0
	var min_elevation: float = deg_to_rad(0.0)
	var max_elevation: float = deg_to_rad(70.0)
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




# Turn on looking at player's target
func turn_on_look() -> void:
	look_at_target = true
	if is_instance_valid(Global.player.targeted):
		target = Global.player.targeted


# Transition to first person camera
func first_person() -> void:
	state = CameraState.FIRSTPERSON
	first_person_camera.make_current()
	Global.targeting_hud_on = true


# Transition to rear underbelly camera
func rear_camera() -> void:
	state = CameraState.REAR
	rear_under_camera.make_current()
	Global.targeting_hud_on = false


# Transition to fly-by cinematic camera
func flyby_camera() -> void:
	state = CameraState.FLYBY
	free_camera.make_current()
	# Reposition to ahead and off to the side of the player
	free_camera.global_position = global_position - \
		Global.player.transform.basis.z*50.0 + \
		Global.player.transform.basis.y*rng.randf_range(-20.0,20.0)+ \
		Global.player.transform.basis.x*rng.randf_range(-20.0,20.0)
	free_camera.look_at(global_position, Vector3.UP)
	Global.targeting_hud_on = false


# Transition to target closeup camera
func target_closeup_camera() -> void:
	if is_instance_valid(Global.player.targeted):
		target = Global.player.targeted
		state = CameraState.TARGETCLOSEUP
		free_camera.make_current()
		view_target_close()
		Global.targeting_hud_on = false


# Transition to target view camera.
# This is where we are looking at target but "over the shoulder"
# from the player themself.
func target_camera() -> void:
	if is_instance_valid(Global.player.targeted):
		state = CameraState.TARGETVIEW
		target = Global.player.targeted
		free_camera.make_current()
		view_target_from_player()
		Global.targeting_hud_on = false


# Pre: target is valid
# Post: Moves free_camera to look at target close up
func view_target_close() -> void:
	# Look at target
	free_camera.look_at(target.global_position, Global.player.transform.basis.y)
	# Reposition to at target position, but back up
	# the camera to get a better view
	free_camera.global_position = target.global_position + \
		transform.basis.z*target_close_up_dist


# Pre: target is valid
# Post: Moves free_camera to look at target from far side of player
func view_target_from_player() -> void:
	# Look at target from player's position
	free_camera.look_at_from_position(global_position, target.global_position, Vector3.UP)
	# Back the camera up and move it vertically to have
	# the player in view, but not blocking center screen
	free_camera.global_position = global_position + \
		free_camera.transform.basis.z*10 + \
		Vector3.UP*5



# TODO TESTING
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
