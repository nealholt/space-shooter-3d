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

var is_dead := false


func _ready() -> void:
	impulse = impulse_std
	# Tell the global script who the player is.
	# Since this is a player controller, it SHOULD
	# be an immediate child of the player.
	Global.player = get_parent()


# Override parent class function
func move_and_turn(mover, delta:float) -> void:
	if is_dead:
		return
	
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


# Override parent class function
func shoot(shooter, delta:float) -> void:
	if is_dead:
		return
	
	# Aim assist audio cue
	if shooter.aim_assist and target and is_instance_valid(target):
		shooter.aim_assist.use_aim_assist(
			shooter, target,
			shooter.weapon_handler.get_bullet_speed())
	
	# Trigger pulled. Try to shoot.
	if shooter.weapon_handler.is_automatic():
		if Input.is_action_pressed("shoot"):
			shooter.weapon_handler.shoot(shooter, target)
	else: # Semiautomatic
		if Input.is_action_just_pressed("shoot"):
			shooter.weapon_handler.shoot(shooter, target)
	
	# Missile lock
	if shooter.missile_lock:
		# Target most centered enemy and begin missile lock
		if Input.is_action_just_pressed("right_shoulder"):
			shooter.missile_lock.attempt_to_start_seeking(shooter)
		# Fire missile if lock is acquired
		if Input.is_action_just_released("right_shoulder"):
			shooter.missile_lock.attempt_to_fire_missile(shooter)
		shooter.missile_lock.update(shooter, delta)
		# Without this next code, autoseeking missile
		# won't work.
		if is_instance_valid(shooter.missile_lock.target):
			target = shooter.missile_lock.target


# Override parent class function
func select_target(targeter:Node3D) -> void:
	if is_dead:
		return
	
	if Input.is_action_just_pressed("right_shoulder"):
		# Target most central enemy team member
		target = Global.get_center_most_from_group(enemy_team,targeter)
		# If target is valid and missile is off cooldown,
		# tell target that missile lock is being sought on
		# it and start the seeking audio and visual
		if is_instance_valid(target):
			# set_targeted is called on a hitbox component
			# and merely modulates the reticle color (for now)
			target.set_targeted(targeter, true)


func misc_actions(actor) -> void:
	if Input.is_action_just_pressed("switch_weapons"):
		actor.weapon_handler.change_weapon()


# Override parent class function
func enter_death_animation() -> void:
	is_dead = true


# Override parent class function
# Died implies that the death animation has concluded.
func died(who_died) -> void:
	# Player died, so go to main menu
	Global.main_scene.to_main_menu()
	Callable(who_died.queue_free).call_deferred()
