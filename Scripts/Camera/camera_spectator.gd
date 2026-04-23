extends Node3D
# Left click / shoot to select target
# Right click / target to change camera mode
# Move with mouse and arrow keys or
# joysticks and accel / decel / brake
# Switch weapons to toggle cursor on or off

# FREE and ATTACHED seem like the best modes. I'm not
# sure the other two are needed.

@onready var camera: Camera3D = $Camera3D

enum CameraMode {
	FREE,
	LOOK,
	LOOK_ATTACHED,
	ATTACHED
}

######## FREE BEHAVIOR PARAMETERS ########
@export var roll_strength:float = 0.05
@export var pitch_strength:float = 0.02
@export var yaw_strength:float = 0.02

@export var roll_lerp:float = 1.5
@export var pitch_lerp:float = 3.0
@export var yaw_lerp:float = 3.0

@export var speed_lerp:float = 0.2 # acceleration
@export var brake_lerp:float = 2.0

@export var min_speed:float = -200.0
@export var max_speed:float = 600.0

var roll:float = 0.0
var pitch:float = 0.0
var yaw:float = 0.0
var speed:float = 0.0

######## LOOK BEHAVIOR PARAMETERS ########
@export var strafe_strength:float = 50.0
@export var strafe_lerp:float = 1.5
var strafe_left_right:float = 0.0
var strafe_up_down:float = 0.0

# Variable to control how close to the poles the
# camera can get. Getting too close to vertical
# can cause the LOOK camera to spin sickeningly.
var pole_limit:float = 0.2

######## ATTACHED BEHAVIOR PARAMETERS ########
@export var rotate_strength:float = 0.02
@export var rotate_lerp:float = 1.5
var rotate_left_right:float = 0.0
var rotate_up_down:float = 0.0

######## OTHER VARIABLES AND PARAMETERS ########
@export var mouse_deadzone:float = 0.15 ## Range 0 to 1

var current_mode := CameraMode.FREE
var im : InputManager
var target:Node3D


func _ready() -> void:
	Global.current_camera = camera
	im = Global.input_man


func _process(delta: float) -> void:
	im.update() # Update the input manager
	
	# Toggle mouse visibility
	if im.switch_weapons:
		if Input.mouse_mode == Input.MouseMode.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Create mouse deadzone for ease of control
	if im.use_mouse_and_keyboard:
		if abs(im.left_right2) < mouse_deadzone:
			im.left_right2 = 0.0
		if abs(im.up_down1) < mouse_deadzone:
			im.up_down1 = 0.0
		if abs(im.left_right1) < mouse_deadzone:
			im.left_right1 = 0.0
	
	# Act on current camera mode
	match current_mode:
		CameraMode.FREE:
			free_behavior(delta)
		CameraMode.LOOK:
			look_behavior(delta)
		CameraMode.LOOK_ATTACHED:
			look_attached_behavior(delta)
		CameraMode.ATTACHED:
			attached_behavior(delta)
	
	# Grab a target from either team (left mouse click)
	if im.shoot_just_pressed:
		var all_targets:= Array()
		for c in Global.red_team_group.get_children():
			all_targets.append(c)
		for c in Global.blue_team_group.get_children():
			all_targets.append(c)
		target = Global.get_center_most(self, all_targets)
	
	# Switch camera mode (right mouse click)
	if im.retarget_just_pressed:
		current_mode = ((current_mode+1) % CameraMode.size()) as CameraMode
		#print(CameraMode.find_key(current_mode))
		
		# If there is no target, be in FREE mode
		if !is_instance_valid(target):
			current_mode = CameraMode.FREE
		
		# In FREE or LOOK mode, reset root node to position
		# and transform of camera
		if current_mode == CameraMode.FREE or current_mode == CameraMode.LOOK:
			self.global_position = camera.global_position
			camera.position = Vector3.ZERO
			self.rotation = camera.rotation
			camera.rotation = Vector3.ZERO
		# In either ATTACHED mode, keep camera where it's at
		# and move the root node to the target location.
		elif (current_mode == CameraMode.LOOK_ATTACHED or current_mode == CameraMode.ATTACHED):
			var temp:Vector3 = camera.global_position
			global_position = target.global_position
			camera.global_position = temp


func free_behavior(delta:float) -> void:
	pitch_roll_yaw_me(self, delta)
	move_forward_backward(delta)


func move_forward_backward(delta:float) -> void:
	accelerate(delta)
	# Move
	global_position += -transform.basis.z * speed * delta


func accelerate(delta:float) -> void:
	# Speed up or slow down
	if im.accelerate:
		speed = lerp(speed, max_speed, speed_lerp * delta)
	elif im.drift: # Reverse
		speed = lerp(speed, min_speed, speed_lerp * delta)
	elif im.brake: # Decelerate
		speed = lerp(speed, 0.0, brake_lerp * delta)


func look_behavior(delta:float) -> void:
	# Face target
	if is_instance_valid(target):
		look_at(target.global_position)
	else:
		return
	# Move closer or further
	move_forward_backward(delta)
	# Reverse course if too close
	if global_position.distance_squared_to(target.global_position) < 1:
		speed = -1.0
	# Get strafe amount
	strafe_left_right = lerp(strafe_left_right, strafe_strength*im.left_right1, strafe_lerp*delta)
	strafe_up_down = lerp(strafe_up_down, strafe_strength*im.up_down1, strafe_lerp*delta)
	# Strafe left right
	global_position += -transform.basis.x * strafe_left_right * delta
	# Before strafing up down, check the following:
	# If this value
	# (global_position - target.global_position).normalized()
	# gets too close to (0, +-1, 0)
	# that means that the camera is approaching the north or
	# south pole above or below and that's bad because side
	# to side motion at those extremes creates a sickening
	# spinning effect. Don't let this happen!
	var proposed_global_position = global_position + transform.basis.y * strafe_up_down * delta
	var vertical:Vector3 = (proposed_global_position - target.global_position).normalized()
	# If below the pole_limit, it's fine to move
	if pole_limit < (Vector3.UP - abs(vertical)).length_squared():
		global_position = proposed_global_position


func look_attached_behavior(delta:float) -> void:
	# Look inward at root node from camera further out
	if is_instance_valid(target):
		global_position = target.global_position
		camera.look_at(global_position)
	else:
		return
	# The following two lines are literally the
	# move_forward_backward function but moving the
	# camera, not the root node.
	# Also now it moves the camera's position, not
	# global position.
	accelerate(delta)
	camera.position += -camera.transform.basis.z * speed * delta
	# Reverse course if too close
	if camera.global_position.distance_squared_to(target.global_position) < 1.0:
		speed = -1.0
	# control movement around target by rotating root
	rotate_left_right = lerp(rotate_left_right, rotate_strength*im.left_right1, rotate_lerp*delta)
	rotate_y(-rotate_left_right)
	rotate_up_down = lerp(rotate_up_down, rotate_strength*im.up_down1, rotate_lerp*delta)
	rotate_x(-rotate_up_down)


func attached_behavior(delta:float) -> void:
	# Keep root node fixed on target position
	if is_instance_valid(target):
		global_position = target.global_position
	else:
		return
	pitch_roll_yaw_me(camera, delta)


func pitch_roll_yaw_me(me:Node3D, delta:float) -> void:
	# Pitch roll and yaw the camera
	roll = lerp(roll, roll_strength*im.left_right2, roll_lerp*delta)
	pitch = lerp(pitch, pitch_strength*im.up_down1, pitch_lerp*delta)
	yaw = lerp(yaw, yaw_strength*im.left_right1, yaw_lerp*delta)
	
	# Pitch roll and yaw
	me.transform.basis = me.transform.basis.rotated(me.transform.basis.z, roll)
	me.transform.basis = me.transform.basis.rotated(me.transform.basis.x, pitch)
	me.transform.basis = me.transform.basis.rotated(me.transform.basis.y, yaw)
	
	# Prevent floating point errors from accumulating. (Not sure if necessary)
	me.transform.basis = me.transform.basis.orthonormalized()
