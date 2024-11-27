extends Node3D

# https://www.reddit.com/r/godot/comments/18w6prn/camera_considerations/

enum CameraState {FIRSTPERSON, REAR, FLYBY, TARGETCLOSEUP, TARGETVIEW}
var state : CameraState

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


func _ready() -> void:
	# Start off in first=person
	first_person()


func _physics_process(delta: float) -> void:
	# Right thumb stick pressed in. Switch to first person
	# and as long as right stick is held in, look at
	# current target.
	if Input.is_action_just_pressed("POV_standard"):
		first_person()
		turn_on_look()
	# Target view. Look towards the target, but from the far
	# side of the player so the player can turn to face target.
	# D-Pad up
	elif Input.is_action_just_pressed("POV_target_look"):
		target_camera()
	# Target close up. Launch the camera out toward the target.
	# D-Pad right
	elif Input.is_action_just_pressed("POV_target_closeup"):
		#camera.top_level = true # Don't inherit parent's transform
		target_closeup_camera()
	# Fixed underslung rear view showing the belly and tail
	# of player's ship looking backwards.
	# D-Pad down
	elif Input.is_action_just_pressed("POV_rear"):
		rear_camera()
	# Cinematic fly-by view. Launch the camera out of ahead
	# of the player and watch the player fly be.
	# D-Pad left
	elif Input.is_action_just_pressed("POV_flyby"):
		flyby_camera()
	# Turn off target look when right thumbstick is released
	elif Input.is_action_just_released("POV_standard"):
		look_at_target = false
	
	# Adjust relevant camera based on the current pov
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
		$turret_motion_component.rotate_and_elevate($Body, $Body/Head, delta, target.global_position)
	elif Global.player:
		# Return to facing forward, or at least way far
		# forward of the nose of the player.
		# Alternatively, maybe I should have a Node3D
		# attached to the player straight ahead that the
		# camera looks at instead.
		var temp_targ_pos : Vector3 = first_person_camera.global_position - Global.player.global_transform.basis.z*10000.0
		$turret_motion_component.rotate_and_elevate($Body, $Body/Head, delta, temp_targ_pos)
	# Show target lead indicator and center crosshair
	# if in first person view
	if state == CameraState.FIRSTPERSON and Global.player and Global.player.controller and is_instance_valid(Global.player.controller.target) and Global.player.weapon_handler and "velocity" in Global.player.controller.target:
		var lead_pos:Vector3 = Global.get_intercept(
			Global.player.global_position,
			Global.player.weapon_handler.get_bullet_speed(),
			Global.player.controller.target)
		Global.set_reticle(first_person_camera, $TargetLeadIndicator, lead_pos)
	else:
		$TargetLeadIndicator.hide()


# Turn on looking at player's target
func turn_on_look() -> void:
	look_at_target = true
	if is_instance_valid(Global.player.controller.target):
		target = Global.player.controller.target


# Transition to first person camera
func first_person() -> void:
	state = CameraState.FIRSTPERSON
	first_person_camera.make_current()
	Global.current_camera = first_person_camera
	Global.targeting_hud_on = true
	# Turn off near miss detectors for all but this camera.
	# Could we instead have just one near miss detector
	# and reparent it to the current camera?
	shutdown_near_miss()
	$Body/Head/FirstPersonCamera/NearMissDetector.process_mode = Node.PROCESS_MODE_ALWAYS


# Transition to rear underbelly camera
func rear_camera() -> void:
	state = CameraState.REAR
	rear_under_camera.make_current()
	Global.current_camera = rear_under_camera
	Global.targeting_hud_on = false
	# Turn off near miss detectors for all but this camera.
	# Could we instead have just one near miss detector
	# and reparent it to the current camera?
	shutdown_near_miss()
	$RearUnderCamera/NearMissDetector.process_mode = Node.PROCESS_MODE_ALWAYS


# Transition to fly-by cinematic camera
func flyby_camera() -> void:
	# In some testing scenes, there is not a player
	# but there is a camera
	if !Global.player:
		return
	state = CameraState.FLYBY
	free_camera.make_current()
	Global.current_camera = free_camera
	# Reposition to ahead and off to the side of the player
	free_camera.global_position = global_position - \
		Global.player.transform.basis.z*50.0 + \
		Global.player.transform.basis.y*rng.randf_range(-20.0,20.0)+ \
		Global.player.transform.basis.x*rng.randf_range(-20.0,20.0)
	free_camera.look_at(global_position, Vector3.UP)
	Global.targeting_hud_on = false
	# Turn off near miss detectors for all but this camera.
	# Could we instead have just one near miss detector
	# and reparent it to the current camera?
	shutdown_near_miss()
	$FreeCamera/NearMissDetector.process_mode = Node.PROCESS_MODE_ALWAYS


# Transition to target closeup camera
func target_closeup_camera() -> void:
	if Global.player and Global.player.controller.target and is_instance_valid(Global.player.controller.target):
		target = Global.player.controller.target
		state = CameraState.TARGETCLOSEUP
		free_camera.make_current()
		Global.current_camera = free_camera
		view_target_close()
		Global.targeting_hud_on = false
		# Turn off near miss detectors for all but this camera.
		# Could we instead have just one near miss detector
		# and reparent it to the current camera?
		shutdown_near_miss()
		$FreeCamera/NearMissDetector.process_mode = Node.PROCESS_MODE_ALWAYS


# Transition to target view camera.
# This is where we are looking at target but "over the shoulder"
# from the player themself.
func target_camera() -> void:
	if is_instance_valid(Global.player.controller.target):
		state = CameraState.TARGETVIEW
		target = Global.player.controller.target
		free_camera.make_current()
		Global.current_camera = free_camera
		view_target_from_player()
		Global.targeting_hud_on = false
		# Turn off near miss detectors for all but this camera.
		# Could we instead have just one near miss detector
		# and reparent it to the current camera?
		shutdown_near_miss()
		$FreeCamera/NearMissDetector.process_mode = Node.PROCESS_MODE_ALWAYS


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


func shutdown_near_miss() -> void:
	$RearUnderCamera/NearMissDetector.process_mode = Node.PROCESS_MODE_DISABLED
	$FreeCamera/NearMissDetector.process_mode = Node.PROCESS_MODE_DISABLED
	$Body/Head/FirstPersonCamera/NearMissDetector.process_mode = Node.PROCESS_MODE_DISABLED
