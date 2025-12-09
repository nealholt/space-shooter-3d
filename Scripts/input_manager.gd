class_name InputManager extends Node

@export var use_mouse_and_keyboard := false
@export var use_inverted := true
# Use this curve to scale mouse input to make the ship easier
# to control
@export var mouse_control_curve : Curve

var inverted := 1.0

var switch_weapons := false
var retarget_just_pressed := false
var retarget_just_released := false # Used to fire missile
var shoot_pressed := false
var shoot_just_pressed := false
var brake := false
var drift := false
var accelerate := false
var accelerate_just_pressed := false
var left_right1 := 0.0 # Left stick
var left_right2 := 0.0 # Right stick
var up_down1 := 0.0 # Left stick
var up_down2 := 0.0 # Right stick

var current_viewport:Viewport
var mouse_pos:Vector2 ## Current mouse position on the viewport


func refresh() -> void:
	if use_inverted:
		inverted = -1.0
	else:
		inverted = 1.0
	if use_mouse_and_keyboard:
		# Show mouse
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		# Confine mouse to the screen and hide it.
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
		# Confine mouse to the screen and show it.
		#Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func toggle_inverted(toggled_on: bool) -> void:
	use_inverted = toggled_on


func toggle_mouse_and_keyboard(toggled_on: bool) -> void:
	use_mouse_and_keyboard = toggled_on


# This is called by player_movement4 and ballistic_movement3,
# the two player control scripts, as im.update().
# I believe it is called every physics update.
func update() -> void:
	switch_weapons = Input.is_action_just_pressed("switch_weapons")
	retarget_just_pressed = Input.is_action_just_pressed("retarget")
	retarget_just_released = Input.is_action_just_released("retarget")
	shoot_pressed = Input.is_action_pressed("shoot")
	shoot_just_pressed = Input.is_action_just_pressed("shoot")
	brake = Input.is_action_pressed("brake")
	drift = Input.is_action_pressed("drift")
	accelerate = Input.is_action_pressed("accelerate")
	accelerate_just_pressed = Input.is_action_just_pressed("accelerate")
	
	if use_mouse_and_keyboard:
		update_mouse_keyboard_input()
	else:
		update_controller_input()


func update_controller_input() -> void:
	left_right1 = Input.get_action_strength("left_stick_left") - Input.get_action_strength("left_stick_right")
	left_right2 = Input.get_action_strength("right_stick_left") - Input.get_action_strength("right_stick_right")
	up_down1 = inverted * (Input.get_action_strength("left_stick_up") - Input.get_action_strength("left_stick_down"))
	up_down2 = inverted * (Input.get_action_strength("right_stick_up") - Input.get_action_strength("right_stick_down"))


# This function updates the current_viewport and
# mouse_pos variables which are used for aim assist.
# Therefore, this function needs called every frame.
func update_mouse_keyboard_input() -> void:
	# This script has to be attached to a node in the scene tree
	# otherwise get_viewport() won't work.
	current_viewport = get_viewport()
	mouse_pos = current_viewport.get_mouse_position()
	var half_size : Vector2 = current_viewport.size / 2
	# Get mouse x and y relative to screen center
	var x_rel_center = half_size.x - mouse_pos.x
	var y_rel_center = inverted*(half_size.y - mouse_pos.y)
	# Roll
	left_right2 = Input.get_axis("right_stick_right", "right_stick_left")
	# Normalize
	# Old way:
	#left_right1 = x_rel_center / half_size.x
	#up_down1 = y_rel_center / half_size.y
	# New way
	left_right1 = sign(x_rel_center)*mouse_control_curve.sample(abs(x_rel_center / half_size.x))
	up_down1 = sign(y_rel_center)*mouse_control_curve.sample(abs(y_rel_center / half_size.y))
	#print(abs(x_rel_center / half_size.x))
