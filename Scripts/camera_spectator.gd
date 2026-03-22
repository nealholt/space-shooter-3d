extends Node3D

@onready var camera: Camera3D = $Camera3D

enum CameraMode {
	FREE,
	LOOK,
	LOOK_ATTACHED,
	ATTACHED
}

######## FREE BEHAVIOR PARAMETERS ########
@export var roll_strength:float = 0.05
@export var pitch_strength:float = 0.03
@export var yaw_strength:float = 0.02

@export var roll_lerp:float = 1.5
@export var pitch_lerp:float = 3.5
@export var yaw_lerp:float = 3.0

@export var speed_lerp:float = 0.1 # acceleration
@export var brake_lerp:float = 2.0

@export var min_speed:float = -200.0
@export var max_speed:float = 600.0

var roll:float = 0.0
var pitch:float = 0.0
var yaw:float = 0.0
var speed:float = 0.0

######## LOOK BEHAVIOR PARAMETERS ########
@export var strafe_strength:float = 100.0
@export var strafe_lerp:float = 1.5
var strafe_left_right:float = 0.0
var strafe_up_down:float = 0.0

# Variable to control how close to the poles the
# camera can get. Getting too close to vertical
# can cause the LOOK camera to spin sickeningly.
var pole_limit:float = 0.1

######## LOOK ATTACHED BEHAVIOR PARAMETERS ########
var dist2target:float
# TODO

######## ATTACHED BEHAVIOR PARAMETERS ########
# TODO

######## OTHER VARIABLES AND PARAMETERS ########
@export var mouse_deadzone:float = 0.5 ## Range 0 to 1

var current_mode := CameraMode.FREE
var im : InputManager
var target:Node3D


func _ready() -> void:
	Global.current_camera = camera
	im = Global.input_man


func _process(delta: float) -> void:
	im.update() # Update the input manager
	
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
		
		# In FREE or LOOK mode, reset root node to position
		# and transform of camera
		if current_mode == CameraMode.FREE or current_mode == CameraMode.LOOK:
			self.global_position = camera.global_position
			camera.position = Vector3.ZERO
			camera.rotation = Vector3.ZERO
		# In either ATTACHED mode, keep camera where it's at
		# and move the root node to the target location.
		#Also get current distance to target.
		elif (current_mode == CameraMode.LOOK_ATTACHED or current_mode == CameraMode.ATTACHED) and is_instance_valid(target):
			var temp:Vector3 = camera.global_position
			global_position = target.global_position
			camera.global_position = temp
			dist2target = temp.distance_to(target.global_position)


func free_behavior(delta:float) -> void:
	# Pitch roll and yaw
	roll = lerp(roll, roll_strength*im.left_right2, roll_lerp*delta)
	pitch = lerp(pitch, pitch_strength*im.up_down1, pitch_lerp*delta)
	yaw = lerp(yaw, yaw_strength*im.left_right1, yaw_lerp*delta)
	
	# Pitch roll and yaw
	transform.basis = transform.basis.rotated(transform.basis.z, roll)
	transform.basis = transform.basis.rotated(transform.basis.x, pitch)
	transform.basis = transform.basis.rotated(transform.basis.y, yaw)
	
	# Prevent floating point errors from accumulating. (Not sure if necessary)
	transform.basis = transform.basis.orthonormalized()
	
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
	# Stop if too close
	if global_position.distance_squared_to(target.global_position) < 1:
		speed = 0.0
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
	# The following two lines are literally the
	# move_forward_backward function but moving the
	# camera, not the root node.
	# Also now it moves the camera's position, not
	# global position.
	accelerate(delta)
	camera.position += -camera.transform.basis.z * speed * delta
	# TODO


func attached_behavior(_delta:float) -> void:
	# Keep root node fixed on target position
	if is_instance_valid(target):
		global_position = target.global_position
	# TODO
