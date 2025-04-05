class_name InputManager extends Node

@export var use_mouse_and_keyboard := true
@export var use_inverted := false
# Use this curve to scale mouse input to make the ship easier to control
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


func refresh() -> void:
	if use_inverted:
		inverted = -1.0
	else:
		inverted = 1.0
	if use_mouse_and_keyboard:
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


func update_mouse_keyboard_input() -> void:
	# This script has to be attached to a node in the scene tree
	# otherwise get_viewport() won't work.
	var half_size : Vector2 = get_viewport().size / 2
	var mouse_pos = get_viewport().get_mouse_position()
	# Get mouse x and y relative to screen center
	var x_rel_center = half_size.x - mouse_pos.x
	var y_rel_center = inverted*(half_size.y - mouse_pos.y)
	# Normalize
	# Old way:
	left_right1 = x_rel_center / half_size.x
	up_down1 = y_rel_center / half_size.y
	# New way
	#left_right1 = sign(x_rel_center)*mouse_control_curve.sample(abs(x_rel_center / half_size.x))
	#up_down1 = sign(y_rel_center)*mouse_control_curve.sample(abs(y_rel_center / half_size.y))
