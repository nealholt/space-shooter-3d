class_name BallisticMovement3

# This is where I put code while I'm trying to figure out
# the right movement style for the game

# Base this on ballistic movement 1,
# but always moving. Cannot brake down to zero
# acceleration is extra
# DONE also add in roll on the right stick

#Variables for controller inputs
var pitch_input: float = 0.0
var roll_input: float = 0.0
var yaw_input: float = 0.0

#This is the strength of the lerp.
# 0.01 is incredibly sluggish and floaty
# Even 0.1 is quite responsive, but a bit gradual
# 1.0 is no lerp at all. aka immediate snap to target value.
# but these values are relevant AFTER multiplying by delta
# so typically 1/60th of this value
var lerp_strength: float =  4.0

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
var impulse_brake: float = 0.0 #40.0 #TODO TESTING
var impulse_lerp: float =  0.2

var impulse := impulse_std

func move(mover, delta:float) -> void:
	var friction := friction_std
	
	var pitch_modifier: float = 1.0
	var roll_modifier: float = 1.0
	var yaw_modifier: float = 1.0
	
	#Brake
	if Input.is_action_pressed("b_button"):
		#impulse = lerp(impulse, impulse_brake, impulse_lerp*delta)
		impulse = impulse_brake
		# Sharper turning while braking
		pitch_modifier = 1.5
		roll_modifier = 1.5
		yaw_modifier = 1.5
	#Accelerate
	elif Input.is_action_pressed("a_button"):
		#impulse = lerp(impulse, impulse_accel, impulse_lerp*delta)
		impulse = impulse_accel
		# Reduced maneuverability while accelerating
		pitch_modifier = 0.9
		roll_modifier = 0.9
		yaw_modifier = 0.9
	#Drift
	elif Input.is_action_pressed("left_shoulder"):
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

	# Pitch roll and yaw
	mover.transform.basis = mover.transform.basis.rotated(mover.transform.basis.z, roll_input*delta)
	mover.transform.basis = mover.transform.basis.rotated(mover.transform.basis.x, pitch_input*delta)
	mover.transform.basis = mover.transform.basis.rotated(mover.transform.basis.y, yaw_input*delta)
	# Prevent floating point errors from accumulating. (Not sure if necessary)
	mover.transform.basis = mover.transform.basis.orthonormalized()
	# New velocity is old velocity * friction + impulse in current direction
	var new_dir = -mover.transform.basis.z * impulse * delta
	# Apply friction on a per unit time basis
	mover.velocity = mover.velocity * (1-friction*delta) + new_dir
	# Move, collide, and bounce off
	# Resources used:
	# https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html
	var collision :KinematicCollision3D = mover.move_and_collide(mover.velocity * delta)
	if collision:
		mover.velocity = mover.velocity.bounce(collision.get_normal())
		# Apply an impulse and a torque to whatever we hit.
		# Except don't really because you should check that
		# we hit a rigid body, otherwise this throws an error.
		# https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html#class-rigidbody2d-method-apply-central-impulse
		# https://www.youtube.com/watch?v=SJuScDavstM
		#collision.get_collider().apply_central_impulse(-collision.get_normal()*100)
		#collision.get_collider().apply_torque_impulse(mover.transform.basis.y)
