class_name FPSMovement1

# This is where I put code while I'm trying to figure out
# the right movement style for the game

# I'm not sure what to base this on,
# but the idea is flight, but with fps-like controls:
# left stick forward/back is accelerate/decelerate
# (but minimum is well above zero)
# left stick side to side is strafe
# right stick has pitch and roll/yaw on it
# for now I'm basing it on flight_movement1

# NEAT idea, but I think this is a NO. It's confusing in my hands


#This is the strength of the lerp.
# 0.01 is incredibly sluggish and floaty
# Even 0.1 is quite responsive, but a bit gradual
# 1.0 is no lerp at all. aka immediate snap to target value.
var lerp_strength: float =  4.8

#Variables for controller inputs
var pitch_input: float = 0.0
var roll_input: float = 0.0
var yaw_input: float = 0.0

#Strength of movements under standard motion
var pitch_std: float = 1.2
var roll_std: float = 0.8
var yaw_std: float = 0.8

# Purely for flight movement controls
var max_speed: float = 12000.0
var min_speed: float = 3000.0
var speed: float = min_speed
var acceleration: float = 3000.0

#Strength of movements under drift
var pitch_drift: float = 1.8
var roll_drift: float = 1.2
var yaw_drift: float = 1.2

#Strength of movements while braking
var pitch_brake: float = 2.4
var roll_brake: float = 1.6
var yaw_brake: float = 1.6

#Strength of movements while accelerating
var pitch_accel: float = 0.6
var roll_accel: float = 0.4
var yaw_accel: float = 0.4

var strafing_horiz:float = 0.0
var strafe_amount:float = 2000.0
var strafe_accel:float = 40.0

func move(mover, delta:float) -> void:
	var pitch_modifier: float = pitch_std
	var roll_modifier: float = roll_std
	var yaw_modifier: float = yaw_std

	# Get acceleration
	var input_strength: float = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	speed += acceleration*input_strength*delta
	speed = clamp(speed, min_speed, max_speed)
	#print('Speed (in fps mode): %s' % speed)

	#Brake
	if input_strength < 0.0:
		pitch_modifier = pitch_brake
		roll_modifier = roll_brake
		yaw_modifier = yaw_brake
	#Accelerate
	elif 0.0 < input_strength:
		pitch_modifier = pitch_accel
		roll_modifier = roll_accel
		yaw_modifier = yaw_accel
	#Drift
	elif Input.is_action_pressed("left_shoulder"):
		pitch_modifier = pitch_drift
		roll_modifier = roll_drift
		yaw_modifier = yaw_drift

	#Get strafe
	input_strength = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	strafing_horiz = lerp(strafing_horiz, input_strength*strafe_amount, strafe_accel*delta)

	#Get pitch
	input_strength = Input.get_action_strength("right_stick_down") - Input.get_action_strength("right_stick_up")
	pitch_input = lerp(pitch_input, input_strength*pitch_modifier, lerp_strength*delta)

	#Get yaw
	input_strength = Input.get_action_strength("right_stick_left") - Input.get_action_strength("right_stick_right")
	roll_input = lerp(roll_input, input_strength*roll_modifier, lerp_strength*delta)
	#This line links roll and yaw.
	yaw_input = roll_input*yaw_modifier/roll_modifier

	mover.transform.basis = mover.transform.basis.rotated(mover.transform.basis.z, roll_input*delta)
	mover.transform.basis = mover.transform.basis.rotated(mover.transform.basis.x, pitch_input*delta)
	mover.transform.basis = mover.transform.basis.rotated(mover.transform.basis.y, yaw_input*delta)
	#This next line is important so that floating point errors don't accumulate.
	mover.transform.basis = mover.transform.basis.orthonormalized()

	#This does work to make drift happen, but it's janky as hell
	#because the change in direction is instantaneous.
	if !Input.is_action_pressed("left_shoulder"):
		mover.velocity = -mover.transform.basis.z * speed * delta + \
			mover.transform.basis.x * strafing_horiz * delta

	mover.move_and_slide()

