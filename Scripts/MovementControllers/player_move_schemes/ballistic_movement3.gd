class_name BallisticMovement3 extends CharacterBodyControlParent

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

var im : InputManager


func _ready() -> void:
	impulse = impulse_std
	im = Global.input_man
	# Tell the global script who the player is.
	# Since this is a player controller, it SHOULD
	# be an immediate child of the player.
	Global.player = get_parent()


# Override parent class function
func move_and_turn(mover, delta:float) -> void:
	if is_dead:
		return
	
	im.update()
	
	friction = friction_std
	
	var pitch_modifier: float = 1.0
	var roll_modifier: float = 1.0
	var yaw_modifier: float = 1.0
	
	handle_engine_audio(mover)
	
	#Brake
	if im.brake:
		#impulse = lerp(impulse, impulse_brake, impulse_lerp*delta)
		impulse = impulse_brake
		# Sharper turning while braking
		pitch_modifier = 1.5
		roll_modifier = 1.5
		yaw_modifier = 1.5
	#Accelerate
	elif im.accelerate:
		#impulse = lerp(impulse, impulse_accel, impulse_lerp*delta)
		impulse = impulse_accel
		# Reduced maneuverability while accelerating
		pitch_modifier = 0.9
		roll_modifier = 0.9
		yaw_modifier = 0.9
	#Drift
	elif im.drift:
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
	pitch_input = lerp(pitch_input,
		im.up_down1*pitch_std*pitch_modifier,
		lerp_strength*delta)

	# Get Roll
	# Right stick's roll is not effected by roll modifiers
	roll_input = lerp(roll_input,
		im.left_right1*roll_std_left_stick*roll_modifier + im.left_right2*roll_std_right_stick,
		lerp_strength*delta)
	# Get yaw using same left stick input as roll
	yaw_input = lerp(yaw_input,
		im.left_right1*yaw_std*yaw_modifier,
		lerp_strength*delta)
	
	super.move_and_turn(mover, delta)


func handle_engine_audio(mover) -> void:
	if !mover.engineAV:
		return
	# NOTE! These transition time numbers
	# are based on nothing in particular!
	if im.brake:
		mover.engineAV.shift2brake(0.0)
	elif im.accelerate:
		mover.engineAV.shift2afterburners(4.0)
	elif im.drift:
		mover.engineAV.shift2drift(1.0)
	else:
		mover.engineAV.shift2default(2.0)


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
		if im.shoot_pressed:
			shooter.weapon_handler.shoot(shooter, target)
	else: # Semiautomatic
		if im.shoot_just_pressed:
			shooter.weapon_handler.shoot(shooter, target)
	
	# Missile lock
	if shooter.missile_lock:
		# Target most centered enemy and begin missile lock
		if im.retarget_just_pressed:
			shooter.missile_lock.attempt_to_start_seeking(shooter)
		# Fire missile if lock is acquired
		if im.retarget_just_released:
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
	
	if im.retarget_just_pressed:
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
	if im.switch_weapons:
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
