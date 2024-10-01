extends CharacterBodyControlParent
class_name BallisticMovement3

# This is where I put code while I'm trying to figure out
# the right movement style for the game

# Base this on ballistic movement 1,
# but always moving. Cannot brake down to zero
# acceleration is extra
# DONE also add in roll on the right stick

#Strength of movements under standard motion
var pitch_std: float = 1.0
var roll_std_left_stick: float = 0.6
var roll_std_right_stick: float = 1.2
var yaw_std: float = 0.6
#Standard air friction and forward impulse
var friction_std: float = 0.99
#var friction_lerp: float =  2.4

#forward motion
var impulse_std: float = 70.0
var impulse_accel: float = 100.0
var impulse_brake: float = 0.0
var impulse_lerp: float =  0.2


func _ready() -> void:
	impulse = impulse_std


func move_and_turn(mover, delta:float) -> void:
	friction = friction_std
	
	var pitch_modifier: float = 1.0
	var roll_modifier: float = 1.0
	var yaw_modifier: float = 1.0
	
	#Brake
	if Input.is_action_pressed("brake"):
		#impulse = lerp(impulse, impulse_brake, impulse_lerp*delta)
		impulse = impulse_brake
		# Sharper turning while braking
		pitch_modifier = 1.5
		roll_modifier = 1.5
		yaw_modifier = 1.5
	#Accelerate
	elif Input.is_action_pressed("accelerate"):
		#impulse = lerp(impulse, impulse_accel, impulse_lerp*delta)
		impulse = impulse_accel
		# Reduced maneuverability while accelerating
		pitch_modifier = 0.9
		roll_modifier = 0.9
		yaw_modifier = 0.9
	#Drift
	elif Input.is_action_pressed("drift"):
		# I like that drift snaps straight to zero impulse and friction
		impulse = 0.0
		friction = 0.0
		# Sharper turning while drifting
		pitch_modifier = 1.3
		roll_modifier = 1.3
		yaw_modifier = 1.3
	else:
		#impulse = lerp(impulse, impulse_std, impulse_lerp*delta)
		impulse = impulse_std

	# Get pitch
	var input_strength: float = Input.get_action_strength("left_stick_down") - Input.get_action_strength("left_stick_up")
	pitch_input = lerp(pitch_input,
		input_strength*pitch_std*pitch_modifier,
		lerp_strength*delta)

	# Get Roll
	# Right stick's roll is not effected by roll modifiers
	input_strength = Input.get_action_strength("left_stick_left") - Input.get_action_strength("left_stick_right")
	var input_strength_right_stick:float = Input.get_action_strength("right_stick_left") - Input.get_action_strength("right_stick_right")
	roll_input = lerp(roll_input,
		input_strength*roll_std_left_stick*roll_modifier + input_strength_right_stick*roll_std_right_stick,
		lerp_strength*delta)
	# Get yaw using same left stick input as roll
	yaw_input = lerp(yaw_input,
		input_strength*yaw_std*yaw_modifier,
		lerp_strength*delta)
	
	super.move_and_turn(mover, delta)
