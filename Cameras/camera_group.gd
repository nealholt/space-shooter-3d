class_name CameraGroup extends Node3D

signal switching_cameras(switching_to:CameraState)

# https://www.reddit.com/r/godot/comments/18w6prn/camera_considerations/

# Static self reference.
# Now any script can reference the camera group like so:
# CameraGroup.cg
# BE WARNED: This will not work correctly if there is more
# than one CameraGroup in a scene.
static var cg:CameraGroup = null

# Controls for looking at target
@export_range(0, 720, 0.1, "radians_as_degrees") var elevation_speed: float = deg_to_rad(100.0)
@export_range(0, 720, 0.1, "radians_as_degrees") var rotation_speed: float = deg_to_rad(100.0)
@export_range(-90, 90, 0.1, "radians_as_degrees") var min_elevation: float = 0.0
@export_range(0, 90, 0.1, "radians_as_degrees") var max_elevation: float = deg_to_rad(80.0)

# This is used for the lerp involved with leaning into turns
# as well as snapping back after looking at a target
@export var lerp_str:float = 3.0

enum CameraState {FIRSTPERSON, REAR, FLYBY, TARGETCLOSEUP, TARGETVIEW, PROFILE, THIRDPERSON}
var state : CameraState

# free_camera has top_level (Under Node3D -> Transform) set to true.
@onready var first_person_camera: Camera3D = $Body/Head/FirstPersonCamera
@onready var rear_under_camera: Camera3D = $RearUnderCamera
@onready var profile_camera: Camera3D = $ProfileCamera
@onready var free_camera: Camera3D = $FreeCamera
@onready var third_person_camera:Camera3D = $ThirdPersonCam

@onready var body:Node3D = $Body
@onready var head:Node3D = $Body/Head

@onready var targ_indicator: TextureRect = $TargetLeadIndicator
@onready var targ_hit: TextureRect = $TargLeadHit
@onready var targ_strong_hit: TextureRect = $TargLeadStrongHit
@onready var targ_shield_hit: TextureRect = $TargLeadShieldHit
@onready var timer_hit_flicker: Timer = $TimerHitFlicker
@onready var current_targ_indicator: TextureRect = targ_indicator

var current_camera:CustomCamera
var turret_motion:TurretMotionComponent
var target_lead_visible := false
enum HIT_TYPE {STANDARD, STRONG, SHIELD}

var target:Node3D

var look_at_target : bool = false
# If true, player is manually swiveling and pitching
# the body and head of the first person camera
# Short for First-Person Manual Override
var fp_manual_override : bool = false

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

var quick_release_timer := 0.0
const QUICK_RELEASE_LIMIT := 0.2 # seconds


# These are used to control a camera indpendent of any ship.
const SPEED = 50.0
var mouse_motion:=Vector2.ZERO
var velocity:=Vector3.ZERO


func _ready() -> void:
	# Make this scene statically accessible
	if cg:
		push_error('ERROR: Unique, static CameraGroup reference has already been set. This should only ever get set once.')
	cg = self
	
	turret_motion = TurretMotionComponent.new()
	turret_motion.elevation_speed = elevation_speed
	turret_motion.rotation_speed = rotation_speed
	turret_motion.min_elevation = min_elevation
	turret_motion.max_elevation = max_elevation
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
	near_center.texture = preload(TargetReticles.RETICLE_FOLDER+'crosshair177.png')
	#near_center.scale = Vector2(0.5, 0.5) # Shrink
	near_center.visible = false
	add_child(near_center)
	beyond_center = Sprite2D.new()
	beyond_center.texture = preload(TargetReticles.RETICLE_FOLDER+'crosshair180.png')
	#beyond_center.scale = Vector2(0.5, 0.5) # Shrink
	beyond_center.visible = false
	add_child(beyond_center)
	# Camera group should typically be attached to ships
	# but if not, use the camera group in spectator mode
	# with mouse and keyboard controls.
	var p = get_parent()
	if p is Ship:
		# We assume the parent is a ship with variables
		# for positioning the FirstPerson and RearUnder
		# cameras.
		if !('fps_cam_position' in p and 'fps_cam_rotation_deg' in p and 'side_cam_position' in p and 'side_cam_rotation_deg' in p):
			push_error('ERROR in CameraGroup _ready. Expect parent to be a ship with certain attributes for positioning camera.')
		body.position = p.fps_cam_position
		body.rotation_degrees = p.fps_cam_rotation_deg
		rear_under_camera.position = p.side_cam_position
		rear_under_camera.rotation = p.side_cam_rotation_deg
		# For now I'm just manually positioning the profile camera
		profile_camera.position = Vector3(7,0,-4)
		profile_camera.rotation_degrees = Vector3(0,90,0)
	else:
		# Turn off _physics_process, which handles gameplay mode
		set_physics_process(false)
	# Connect to camera signal. Always switch to first
	# person camera whenever there's an issue with the
	# current camera.
	first_person_camera.abandon_camera.connect(switch_cameras)
	rear_under_camera.abandon_camera.connect(switch_cameras)
	profile_camera.abandon_camera.connect(switch_cameras)
	free_camera.abandon_camera.connect(switch_cameras)
	third_person_camera.abandon_camera.connect(switch_cameras)
	# Start off in firstperson
	current_camera = first_person_camera
	state = CameraState.FIRSTPERSON
	switch_cameras.call_deferred()


# For gameplay mode
func _physics_process(delta: float) -> void:
	# Track elapsed time for pov standard held down
	quick_release_timer += delta
	# Right thumb stick pressed in. Switch to first person
	# and as long as right stick is held in, look at
	# current target.
	# Control key for mouse and keyboard.
	if Input.is_action_just_pressed("POV_standard"):
		# Only reset the timer if NOT transitioning from third
		# to first, otherwise you can't rapid swap becuase
		# on release it swaps back to third.
		if state != CameraState.THIRDPERSON:
			# Track how long this button gets held
			quick_release_timer = 0.0 # reset
		# Switch to first person
		switch_cameras(CameraState.FIRSTPERSON)
		turn_on_look()
	# Target view. Look towards the target, but from the far
	# side of the player so the player can turn to face target.
	# D-Pad up.
	elif Input.is_action_just_pressed("POV_target_look"):
		switch_cameras(CameraState.TARGETVIEW)
	# Target close up. Launch the camera out toward the target.
	# D-Pad right
	elif Input.is_action_just_pressed("POV_target_closeup"):
		switch_cameras(CameraState.TARGETCLOSEUP)
	# Fixed underslung rear view showing the belly and tail
	# of player's ship looking backwards.
	# D-Pad down
	elif Input.is_action_just_pressed("POV_rear"):
		switch_cameras(CameraState.REAR)
	# Cinematic fly-by view. Launch the camera out of ahead
	# of the player and watch the player fly be.
	# D-Pad left
	elif Input.is_action_just_pressed("POV_flyby"):
		switch_cameras(CameraState.FLYBY)
	# Turn off target look when right thumbstick is released
	elif Input.is_action_just_released("POV_standard"):
		look_at_target = false
		# If this was a quick release from first person,
		# then switch to third person
		if state == CameraState.FIRSTPERSON and quick_release_timer < QUICK_RELEASE_LIMIT:
			switch_cameras(CameraState.THIRDPERSON)
	# Profile camera initially used for testing
	elif Input.is_action_just_released("POV_profile"):
		switch_cameras(CameraState.PROFILE)
	
	current_camera.update_camera.call()
	
	# Look at target with first-person cam
	if look_at_target and state == CameraState.FIRSTPERSON and is_instance_valid(target):
		# Old version
		turret_motion.rotate_and_elevate(body, head, delta, target.global_position)
		# New version with lerp
		#turret_motion.rotate_and_elevate_lerp(body, head, delta, target.global_position)
	# Return to facing forward, or at least way far
	# forward of the nose of the player.
	# Alternatively, maybe I should have a Node3D
	# attached to the player straight ahead that the
	# camera looks at instead.
	elif !fp_manual_override and Global.player:
		# The 10000.0 is simply to indicate "far ahead." Is it needed?
		var temp_targ_pos : Vector3 = first_person_camera.global_position - Global.player.global_transform.basis.z*10000.0
		# Old version
		#turret_motion.rotate_and_elevate(body, head, delta, temp_targ_pos)
		# New version with lerp
		turret_motion.rotate_and_elevate_lerp(body, head, delta, temp_targ_pos)
	
	# Show target lead indicator and center crosshair
	# if in first or third person view
	# (state == CameraState.FIRSTPERSON or state == CameraState.THIRDPERSON)
	# and the player exists
	# Global.player
	# and the player has a controller
	# Global.player.controller
	# and the target is valid
	# is_instance_valid(Global.player.controller.target)
	# and there is a current weapon
	# Global.player.weapon_handler
	# and the target is not yet dead
	# !Global.player.controller.target.is_dead()
	if (state == CameraState.FIRSTPERSON or state == CameraState.THIRDPERSON) and \
	Global.player and Global.player.controller and \
	is_instance_valid(Global.player.controller.target) and \
	Global.player.weapon_handler and \
	!Global.player.controller.target.is_dead():
		var vel:Vector3 = Global.player.controller.target.get_velocity()
		if vel == Vector3.ZERO:
			current_targ_indicator.hide()
			target_lead_visible = false
		else:
			var lead_pos:Vector3 = Global.get_intercept(
				Global.player.global_position,
				Global.player.weapon_handler.current_weapon.bullet_speed,
				Global.player.controller.target)
			Global.set_reticle(current_targ_indicator, lead_pos)
			target_lead_visible = true
	else:
		current_targ_indicator.hide()
		target_lead_visible = false
	# Draw a line from the center of the screen to the mouse position.
	# This is how House of the Dying Sun does mouse controls.
	if InputManager.im.use_mouse_and_keyboard and Global.targeting_hud_on:
		var mouse_pos:Vector2 = InputManager.im.mouse_pos #get_viewport().get_mouse_position()
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
			near_center.visible = true
			beyond_center.visible = false
			near_center.global_position = mouse_pos


# Turn on looking at player's target
func turn_on_look() -> void:
	look_at_target = true
	if is_instance_valid(Global.player.controller.target):
		target = Global.player.controller.target


# Switch cameras. Defaults to first person camera
func switch_cameras(cs:CameraState = CameraState.FIRSTPERSON) -> void:
	Global.targeting_hud_on = false
	mouse_guide.visible = false
	near_center.visible = false
	beyond_center.visible = false
	current_camera.deactivate_camera.call()
	# Update state
	state = cs
	# Update camera
	match state:
		CameraState.FIRSTPERSON:
			current_camera = first_person_camera
			Global.targeting_hud_on = true
		CameraState.REAR:
			current_camera = rear_under_camera
		CameraState.FLYBY:
			current_camera = free_camera
			current_camera.set_as_flyby()
		CameraState.PROFILE:
			current_camera = profile_camera
		CameraState.TARGETCLOSEUP:
			current_camera = free_camera
			current_camera.set_as_targetcloseup()
		CameraState.TARGETVIEW:
			current_camera = free_camera
			current_camera.set_as_targetview()
		CameraState.THIRDPERSON:
			current_camera = third_person_camera
			Global.targeting_hud_on = true
	current_camera.activate_camera.call()
	Global.current_camera = current_camera
	switching_cameras.emit(state)


func is_mouse_near_center() -> bool:
	return InputManager.im.use_mouse_and_keyboard and Global.targeting_hud_on and near_center.visible

func is_first_or_third() -> bool:
	return state == CameraState.FIRSTPERSON or state == CameraState.THIRDPERSON

func visualize_hit(hit:HIT_TYPE) -> void:
	# Hide current target lead indicator
	current_targ_indicator.visible = false
	# Swap to selected target lead indicator
	match hit:
		HIT_TYPE.STANDARD:
			current_targ_indicator = targ_hit
		HIT_TYPE.STRONG:
			current_targ_indicator = targ_strong_hit
		HIT_TYPE.SHIELD:
			current_targ_indicator = targ_shield_hit
	# Determine whether or not to show new lead indicator
	if target_lead_visible:
		current_targ_indicator.visible = true
	# Start timer to ultimately switch back to default
	timer_hit_flicker.start()


func _on_timer_hit_flicker_timeout() -> void:
	# Hide current target lead indicator
	current_targ_indicator.visible = false
	# Swap to standard target lead indicator
	current_targ_indicator = targ_indicator
	# Determine whether or not to show lead indicator
	if target_lead_visible:
		current_targ_indicator.visible = true


func get_first_person_near_miss() -> Area3D:
	return first_person_camera.get_near_miss_area()

func get_third_person_near_miss() -> Area3D:
	return third_person_camera.get_near_miss_area()


func get_look_camera() -> Camera3D:
	if state == CameraState.THIRDPERSON:
		return third_person_camera
	else:
		return first_person_camera


func set_fp_manual_override(b:bool) -> void:
	fp_manual_override = b

# Rotate the first person camera
# roty is the swivel
# rotx is the pitch
func rotate_fp_cam(rotx:float, roty:float, delta:float) -> void:
	# if current camera is not first person OR using target look then return
	if state != CameraState.FIRSTPERSON or look_at_target:
		return
	if rotx!=0.0:
		turret_motion.swivel_toward(body, rotx, delta*lerp_str)
	if roty!=0.0:
		turret_motion.pitch_toward(head, roty, delta*lerp_str)
