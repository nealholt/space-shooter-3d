extends CharacterBodyControlParent
class_name FlightMovement1

# This is where I put code while I'm trying to figure out
# the right movement style for the game


#Strength of movements under standard motion
var pitch_std: float = 1.2
var roll_std: float = 0.8
var yaw_std: float = 0.8

# Purely for flight movement controls
var max_speed: float = 10250.0
var speed: float = 0.0
var acceleration: float = 350.0

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

func move(mover, delta:float) -> void:
	var pitch_modifier: float = pitch_std
	var roll_modifier: float = roll_std
	var yaw_modifier: float = yaw_std
	#Brake
	if Input.is_action_pressed("brake"):
		speed -= acceleration*delta
		speed = clamp(speed, 0.0, max_speed)
		pitch_modifier = pitch_brake
		roll_modifier = roll_brake
		yaw_modifier = yaw_brake
	#Accelerate
	elif Input.is_action_pressed("accelerate"):
		speed += acceleration*delta
		speed = clamp(speed, 0.0, max_speed)
		pitch_modifier = pitch_accel
		roll_modifier = roll_accel
		yaw_modifier = yaw_accel
	#Drift
	elif Input.is_action_pressed("drift"):
		pitch_modifier = pitch_drift
		roll_modifier = roll_drift
		yaw_modifier = yaw_drift

	#print('Speed (in flight mode):')
	#print(speed)

	#Get pitch
	var input_strength: float = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	pitch_input = lerp(pitch_input, input_strength*pitch_modifier, lerp_strength*delta)

	#Get yaw
	input_strength = Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
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
	#Drift when left_shoulder is held
	if !Input.is_action_pressed("drift"):
		mover.velocity = -mover.transform.basis.z * speed * delta
	mover.move_and_slide()
