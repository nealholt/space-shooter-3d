class_name CameraGroup extends Node3D

# https://www.reddit.com/r/godot/comments/18w6prn/camera_considerations/

# Controls for looking at target
@export var elevation_speed_deg:float = 100.0
@export var rotation_speed_deg:float = 100.0
@export var min_elevation_deg:float = 0.0
@export var max_elevation_deg:float = 80.0

enum CameraState {FIRSTPERSON, REAR, FLYBY, TARGETCLOSEUP, TARGETVIEW}
var state : CameraState

# free_camera has top_level set to true. Other cameras
# are children of the player.
#@onready var first_person_camera: Camera3D = $FirstPersonCamera
@onready var first_person_camera: Camera3D = $Body/Head/FirstPersonCamera
@onready var rear_under_camera: Camera3D = $RearUnderCamera
@onready var free_camera: Camera3D = $FreeCamera

@onready var turret_motion:TurretMotionComponent = $turret_motion_component
@onready var body:Node3D = $Body
@onready var head:Node3D = $Body/Head

var rng = RandomNumberGenerator.new() # For positioning flyby camera

var target:Node3D

const target_close_up_dist:=-30.0

var look_at_target : bool = false

var mouse_guide:Line2D
# Custom images for the mouse cursor.
var near_center:Sprite2D
var beyond_center:Sprite2D
# Radius (squared)  from the center of the screen within which
# guns aim at the mouse rather than straight ahead
const MOUSE_CENTER_RADIUS := 200.0*200.0
# Radius (squared)  from the center of the screen within which
# the mouse guide is hidden
const MOUSE_HIDE_RADIUS := 100.0*100.0


func _ready() -> void:
	turret_motion.elevation_speed = deg_to_rad(elevation_speed_deg)
	turret_motion.rotation_speed = deg_to_rad(rotation_speed_deg)
	turret_motion.min_elevation = deg_to_rad(min_elevation_deg)
	turret_motion.max_elevation = deg_to_rad(max_elevation_deg)
	# Start off in first=person
	first_person()
	# Set the first two points in the mouse_guide line to
	# be center screen. Two points are added because 
	# _physics_process always resets the second point,
	# so there has to be an existing second point to reset.
	mouse_guide = Line2D.new()
	add_child(mouse_guide)
	mouse_guide.width = 1.0
	var center_screen := Vector2(get_viewport().size) / 2.0
	mouse_guide.add_point(center_screen)
	mouse_guide.add_point(center_screen)
	mouse_guide.visible = false
	# Set cursor images
	near_center = Sprite2D.new()
	near_center.texture = load("res://Assets/Images/crosshair177.png")
	#near_center.scale = Vector2(0.5, 0.5) # Shrink
	near_center.visible = false
	add_child(near_center)
	beyond_center = Sprite2D.new()
	beyond_center.texture = load("res://Assets/Images/crosshair180.png")
	#beyond_center.scale = Vector2(0.5, 0.5) # Shrink
	beyond_center.visible = false
	add_child(beyond_center)
	# Camera groups should only be attached to ships.
	# We assume the parent is a ship with variables
	# for positioning the FirstPerson and RearUnder
	# cameras.
	var p:Ship = get_parent()
	if !('fps_cam_position' in p and 'fps_cam_rotation_deg' in p and 'side_cam_position' in p and 'side_cam_rotation_deg' in p):
		push_error('ERROR in CameraGroup _ready. Expect parent to be a ship with certain attributes for positioning camera.')
	body.position = p.fps_cam_position
	body.rotation = p.fps_cam_rotation_deg
	rear_under_camera.position = p.side_cam_position
	rear_under_camera.rotation = p.side_cam_rotation_deg


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
		turret_motion.rotate_and_elevate(body, head, delta, target.global_position)
	elif Global.player:
		# Return to facing forward, or at least way far
		# forward of the nose of the player.
		# Alternatively, maybe I should have a Node3D
		# attached to the player straight ahead that the
		# camera looks at instead.
		# The 10000.0 is simply to indicate "far ahead." Is it needed?
		var temp_targ_pos : Vector3 = first_person_camera.global_position - Global.player.global_transform.basis.z*10000.0
		turret_motion.rotate_and_elevate(body, head, delta, temp_targ_pos)
	# Show target lead indicator and center crosshair
	# if in first person view
	# state == CameraState.FIRSTPERSON
	# and the player exists
	# Global.player
	# and the player has a controller
	# Global.player.controller
	# and the target is valid
	# is_instance_valid(Global.player.controller.target)
	# and there is a current weapon
	# Global.player.weapon_handler
	# and the target has a velocity
	# "velocity" in Global.player.controller.target
	# and the target has not yet instantiated a death_animation_timer
	# !Global.player.controller.target.death_animation_timer
	if state == CameraState.FIRSTPERSON and Global.player and Global.player.controller and is_instance_valid(Global.player.controller.target) and Global.player.weapon_handler and "velocity" in Global.player.controller.target and !Global.player.controller.target.death_animation_timer:
		var lead_pos:Vector3 = Global.get_intercept(
			Global.player.global_position,
			Global.player.weapon_handler.get_bullet_speed(),
			Global.player.controller.target)
		Global.set_reticle(first_person_camera, $TargetLeadIndicator, lead_pos)
	else:
		$TargetLeadIndicator.hide()
	# Draw a line from the center of the screen to the mouse position.
	# This is how House of the Dying Sun does mouse controls.
	if Global.input_man.use_mouse_and_keyboard and Global.targeting_hud_on:
		var mouse_pos:Vector2 = Global.input_man.mouse_pos #get_viewport().get_mouse_position()
		mouse_guide.set_point_position(1, mouse_pos)
		# Hide the mouse_guide if it's close to center
		var guide_length:float = mouse_pos.distance_squared_to(mouse_guide.get_point_position(0))
		mouse_guide.visible = guide_length > MOUSE_HIDE_RADIUS
		# Set cursor based on distance to center.
		# The idea is that later this would indicate whether or
		# not auto-aim has kicked in.
		if guide_length > MOUSE_CENTER_RADIUS:
			near_center.visible = false
			beyond_center.visible = true
			beyond_center.global_position = mouse_pos
		else:
			beyond_center.visible = false
			near_center.visible = true
			near_center.global_position = mouse_pos


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
	shutdown_near_miss()
	first_person_camera.turn_on_near_miss()


# Transition to rear underbelly camera
func rear_camera() -> void:
	state = CameraState.REAR
	rear_under_camera.make_current()
	Global.current_camera = rear_under_camera
	Global.targeting_hud_on = false
	mouse_guide.visible = false
	near_center.visible = false
	beyond_center.visible = false
	# Turn off near miss detectors for all but this camera.
	shutdown_near_miss()
	rear_under_camera.turn_on_near_miss()


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
	mouse_guide.visible = false
	near_center.visible = false
	beyond_center.visible = false
	# Turn off near miss detectors for all but this camera.
	shutdown_near_miss()
	free_camera.turn_on_near_miss()


# Transition to target closeup camera
func target_closeup_camera() -> void:
	if !(Global.player and Global.player.controller.target and is_instance_valid(Global.player.controller.target)):
		return
	target = Global.player.controller.target
	state = CameraState.TARGETCLOSEUP
	free_camera.make_current()
	Global.current_camera = free_camera
	view_target_close()
	Global.targeting_hud_on = false
	mouse_guide.visible = false
	near_center.visible = false
	beyond_center.visible = false
	# Turn off near miss detectors for all but this camera.
	shutdown_near_miss()
	free_camera.turn_on_near_miss()


# Transition to target view camera.
# This is where we are looking at target but "over the shoulder"
# from the player themself.
func target_camera() -> void:
	if !is_instance_valid(Global.player.controller.target):
		return
	state = CameraState.TARGETVIEW
	target = Global.player.controller.target
	free_camera.make_current()
	Global.current_camera = free_camera
	view_target_from_player()
	Global.targeting_hud_on = false
	mouse_guide.visible = false
	near_center.visible = false
	beyond_center.visible = false
	# Turn off near miss detectors for all but this camera.
	shutdown_near_miss()
	free_camera.turn_on_near_miss()


# Pre: target is valid
# Post: Moves free_camera to look at target close up
func view_target_close() -> void:
	# To avoid this error:
	# "Node origin and target are in the same position, look_at() failed."
	# Make sure to position the camera before calling look_at.
	
	# Reposition to at target position, but back up
	# the camera to get a better view
	free_camera.global_position = target.global_position + \
		Global.player.transform.basis.z*target_close_up_dist
	# Look at target
	free_camera.look_at(target.global_position, Global.player.transform.basis.y)


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
	first_person_camera.turn_off_near_miss()
	rear_under_camera.turn_off_near_miss()
	free_camera.turn_off_near_miss()

func is_mouse_near_center() -> bool:
	return Global.input_man.use_mouse_and_keyboard and Global.targeting_hud_on and near_center.visible

func is_first_person() -> bool:
	return state == CameraState.FIRSTPERSON
