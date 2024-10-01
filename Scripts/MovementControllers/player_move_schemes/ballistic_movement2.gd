extends CharacterBodyControlParent
class_name BallisticMovement2

# This is where I put code while I'm trying to figure out
# the right movement style for the game

var impulse_lerp: float =  0.6
var friction_lerp: float =  2.4

#Strength of movements under standard motion
var pitch_std: float = 1.2
var roll_std: float = 0.8
var yaw_std: float = 0.8
#Standard air friction and forward impulse
var friction_std: float = 0.9
#forward motion
var impulse_std: float = 80.0

#Strength of movements under drift
var pitch_drift: float = 1.8
var roll_drift: float = 1.2
var yaw_drift: float = 1.2
#Drift air friction and forward impulse
var friction_drift: float = 0.0
#forward motion
var impulse_drift: float = 0.0

#Strength of movements while braking
var pitch_brake: float = 2.4
var roll_brake: float = 1.6
var yaw_brake: float = 1.6
#Drift air friction and forward impulse
var friction_brake: float = 0.97
#forward motion
var impulse_brake: float = 0.0

#Strength of movements while accelerating
var pitch_accel: float = 0.6
var roll_accel: float = 0.4
var yaw_accel: float = 0.4
#Drift air friction and forward impulse
var friction_accel: float = 0.5
#forward motion
var impulse_accel: float = 120.0


func _ready() -> void:
	impulse = 0.0
	friction = 1.0


# This second iteration of ballistic movement lerps
# impulse and friction, includes acceleration,
# and modifies turn rate based on drift or braking
func move_and_turn(mover, delta:float) -> void:
	var pitch_modifier: float = pitch_std
	var roll_modifier: float = roll_std
	var yaw_modifier: float = yaw_std
	#Accelerating
	if Input.is_action_pressed("accelerate"):
		impulse = lerp(impulse, impulse_accel, impulse_lerp*delta)
		friction = lerp(friction, friction_accel, friction_lerp*delta)
		pitch_modifier = pitch_accel
		roll_modifier = roll_accel
		yaw_modifier = yaw_accel
	#Brake
	elif Input.is_action_pressed("brake"):
		impulse = lerp(impulse, impulse_brake, impulse_lerp*delta)
		friction = lerp(friction, friction_brake, friction_lerp*delta)
		pitch_modifier = pitch_brake
		roll_modifier = roll_brake
		yaw_modifier = yaw_brake
	#Drift
	elif Input.is_action_pressed("drift"):
		#Drifting immediately drops impulse and friction to zero
		impulse = impulse_drift
		friction = friction_drift
		pitch_modifier = pitch_drift
		roll_modifier = roll_drift
		yaw_modifier = yaw_drift
	else:
		#Always accelerate unless braking or drifting
		impulse = lerp(impulse, impulse_std, impulse_lerp*delta)
		friction = lerp(friction, friction_std, friction_lerp*delta)

	#Get pitch
	var input_strength: float = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	pitch_input = lerp(pitch_input,
		input_strength*pitch_modifier,
		lerp_strength*delta)

	#Get yaw
	input_strength = Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
	roll_input = lerp(roll_input,
		input_strength*roll_modifier,
		lerp_strength*delta)

	#Get roll (which is linked to yaw input)
	input_strength = Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
	yaw_input = lerp(yaw_input,
		input_strength*yaw_modifier,
		lerp_strength*delta)
	
	super.move_and_turn(mover, delta)
