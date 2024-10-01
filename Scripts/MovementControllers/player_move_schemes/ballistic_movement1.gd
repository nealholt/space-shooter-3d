extends CharacterBodyControlParent
class_name BallisticMovement1

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


func _ready() -> void:
	impulse = 0.0
	friction = 1.0


func move_and_turn(mover, delta:float) -> void:
	#Always accelerate unless braking or drifting
	impulse = impulse_std
	friction = friction_std
	var pitch_modifier: float = pitch_std
	var roll_modifier: float = roll_std
	var yaw_modifier: float = yaw_std
	#Brake
	if Input.is_action_pressed("brake"):
		impulse = 0.0
		friction = 0.8 #More friction
	#Drift
	elif Input.is_action_pressed("drift"):
		impulse = 0.0
		friction = 0.0

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
	#This line links roll and yaw.
	yaw_input = roll_input*yaw_modifier/roll_modifier
	
	super.move_and_turn(mover, delta)
