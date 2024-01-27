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
