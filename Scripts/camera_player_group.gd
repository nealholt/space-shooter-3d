extends Node3D

# https://www.reddit.com/r/godot/comments/18w6prn/camera_considerations/

enum CameraState {FIRSTPERSON, REAR, FLYBY, TARGETCLOSEUP, TARGETVIEW}
var state = CameraState.FIRSTPERSON

# free_camera has top_level set to true. Other cameras
# are children of the player.
@onready var first_person_camera: Camera3D = $FirstPersonCamera
@onready var rear_under_camera: Camera3D = $RearUnderCamera
@onready var free_camera: Camera3D = $FreeCamera

var rng = RandomNumberGenerator.new() # For positioning flyby camera

var target:Node3D

const target_close_up_dist:=-30.0

var look_at_target : bool = false
@export var look_speed : float = 59.0

func _physics_process(_delta: float) -> void:
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
		#rotate_and_elevate(delta, $Body, $Body/Head, target.global_position)
		first_person_camera.look_at(target.global_position, Global.player.global_transform.basis.y)
		
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
		#var temp_targ_pos : Vector3 = first_person_camera.global_position + Global.player.global_transform.basis.z*10000.0
		#rotate_and_elevate(delta, $Body, $Body/Head, temp_targ_pos)
		first_person_camera.look_at(first_person_camera.global_position - Global.player.global_transform.basis.z*10000.0, Global.player.global_transform.basis.y)
		
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
func rotate_and_elevate(delta: float, body:Node3D, head:Node3D, target_pos:Vector3) -> void:
	var rotation_speed : float = 5.0
	var elevation_speed : float = 5.0
	var min_elevation: float = deg_to_rad(0.0)
	var max_elevation: float = deg_to_rad(60.0)
	# Project the target onto the XZ plane of the turret.
	# This works even if the turret is rotated!
	# Project current_target onto the plane perpendicular to body.global_basis.y
	# https://math.stackexchange.com/questions/728481/3d-projection-onto-a-plane
	# plane_norm is the vector our plane is perpendicular to
	var plane_norm:Vector3 = body.global_basis.y
	# projected is the vector indicating how far above/below
	# the target point is from our plane
	var projected:Vector3 = (target_pos.dot(plane_norm) / plane_norm.dot(plane_norm)) * plane_norm
	# by subtracting projected from target, we get the projected point.
	# This is the point to rotate the turret toward
	var rotation_targ:Vector3 = target_pos - projected
	
	# Get the desired rotation
	# Get the angle to projected point
	var y_angle:float = body.global_basis.z.angle_to(rotation_targ)
	# Transform target to body local space. This is useful to
	# know if we should rotate left or right because angle_to
	# always returns a positive value.
	var local_target:Vector3 = body.to_local(target_pos)
	
	# Rotate toward it
	# Calculate step size and direction. If we need to rotate
	# less than out max rotation, then snap to desired angle
	# using the min function
	var final_y:float = sign(local_target.x) * min(rotation_speed * delta, y_angle)
	# rotate body
	body.rotate_y(final_y)
	
	# Rotation is complete, not we elevate
	# Project the target onto the ZY plane of the turret.
	# This works even if the turret is rotated!
	# Project current_target onto the plane perpendicular to head.global_basis.y
	# https://math.stackexchange.com/questions/728481/3d-projection-onto-a-plane
	# plane_norm is the vector our plane is perpendicular to
	plane_norm = head.global_basis.x
	# projected is the vector indicating how far above/below
	# the target point is from our plane
	projected = (target_pos.dot(plane_norm) / plane_norm.dot(plane_norm)) * plane_norm
	# by subtracting projected from target, we get the projected point.
	# This is the point to rotate the turret toward
	var elevation_targ:Vector3 = target_pos - projected
	
	# Get the desired rotation
	# Get the angle to projected point
	var x_angle:float = head.global_basis.z.angle_to(elevation_targ)
	
	# Elevate toward it
	# One more negative sign because pitching up is negative
	var elevation_sign:float = -sign(head.to_local(target_pos).y)
	var final_x:float = elevation_sign * min(elevation_speed * delta, x_angle)
	#print(rad_to_deg(final_x))
	# elevate head
	head.rotate_x(final_x)
	# Clamp elevation within limits
	# Reverse and negate max and min because up is negative and
	# down is positive
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

