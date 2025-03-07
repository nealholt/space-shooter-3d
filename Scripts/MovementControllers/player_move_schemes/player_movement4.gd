class_name PlayerMovement4 extends CharacterBodyControlParent

# Differences between this and Version 3
#     Tighter pitch radius: pitch_std from 1 -> 1.8
#     Reduced pitch, roll, yaw while accelerating: 0.9 -> 0.3
#     Reduced pitch, roll, yaw while drifting: 1.3 -> 0.7
#     More roll on right stick: 1.2 -> 2
#     Mild "fine-grained" pitch on right stick: 0.4
#     Stronger impulse acceleration: 100 -> 6500
#     This stronger accel is offset by use of impulse_lerp
# such that the impulse isn't instantaneous, but has to be
# lerped up to and back down from, meanwhile, turn rate is
# reduced.
#     Slower impulse lerp: 0.2 -> 1.0
#     Pitch, roll, yaw maxes out at default speed and
# scales based on difference between current speed and
# default speed. See everything related to
# "turn_reduction" below.
#     Temporary acceleration (You can't just keep holding the button)
# Implemented with all the variables below starting with
# accel_max_duration. <----- Except I didn't like it so I 
# kept the code, but set the values such that accel shouldn't
# ever really run out.
#     I lowered friction from 0.99 (which was misleading because
# it's also getting multiplied by delta which is typically 1/60)
# to 0.8 to get a "driftier" feel. Zero is full ballistic
# "asteroids" controls.
#     No brakes (EXCEPT WE KEPT THEM IN FOR TESTING PURPOSES)

#Strength of movements under standard motion
var pitch_std: float = 1.8
var roll_std_left_stick: float = 0.6
var roll_std_right_stick: float = 2.0
var pitch_std_right_stick: float = 0.4
var yaw_std: float = 0.6
#Standard air friction and forward impulse
var friction_std: float = 0.8 # Lower is closer "asteroids" controls
#var friction_lerp: float =  2.4

#forward motion
var impulse_std: float = 60.0
var impulse_accel: float = 6500.0
var impulse_brake: float = 0.0
var impulse_lerp: float = 1.0

# Scaling factor for reducing turn rate as a function of speed
# The smaller this number is, the more turn rate will be
# reduced at high speed.
# If turn_reduction_factor is 10, then every 10 difference
# between speed and default speed will divide turn rate by 1 more.
var turn_reduction_factor:float = 40.0

# Can't accelerate forever. These variables control how
# long ship can accelerate and how long it takes for the
# acceleration bar to refill.
var accel_max_duration:float = 500.0 # seconds Used to be 5.0, but I didn't like the "feature"
var accel_available:float = 500.0 # seconds Used to be 5.0, but I didn't like the "feature"
# accel_regen_rate will be multiplied by delta. The result
# will be added to accel_available
var accel_regen_rate:float = 100.0 #Used to be 1.0, but I didn't like the "feature"
# Can't accelerate if accel_available is less than accel_min
var accel_min:float = 1.5
var is_accelerating:bool

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
	
	is_accelerating = false
	friction = friction_std
	
	impulse = impulse_std
	
	var pitch_modifier: float = 1.0
	var roll_modifier: float = 1.0
	var yaw_modifier: float = 1.0
	
	# Can't start to accelerate unless sufficient "fuel"
	# is available. Can continue to accelerate down to
	# zero if accel button is already held down.
	var can_accelerate = true
	if im.accelerate:
		can_accelerate = accel_available > accel_min
	
	#Brake
	if im.brake:
		#impulse = lerp(impulse, impulse_brake, impulse_lerp*delta)
		impulse = impulse_brake
		# Sharper turning while braking
		pitch_modifier = 1.5
		roll_modifier = 1.5
		yaw_modifier = 1.5
	#Accelerate
	elif im.accelerate and can_accelerate:
		# Acceleration is now limited by a rechargeable resource
		# stored in the accel_available variable.
		is_accelerating = accel_available > 0
		if is_accelerating:
			impulse = lerp(impulse, impulse_accel, impulse_lerp*delta)
			#impulse = impulse_accel
			accel_available -= delta
		# Reduced maneuverability while accelerating
		pitch_modifier = 0.3
		roll_modifier = 0.3
		yaw_modifier = 0.3
	#Drift
	elif im.drift:
		# I like that drift snaps straight to zero impulse and friction
		impulse = 0.0
		friction = 0.0
		# Sharper turning while drifting
		pitch_modifier = 0.7
		roll_modifier = 0.7
		yaw_modifier = 0.7
	
	handle_engine_audio(mover)
	
	# Recharge acceleration "fuel"
	if !im.accelerate:
		accel_available = min(accel_available+accel_regen_rate*delta, accel_max_duration)
	
	# Calculate reduced turn rate based on difference
	# between speed and default speed.
	# Don't apply if drifting.
	if !im.drift:
		var speed:float = mover.velocity.length()
		var turn_reduction:float = max(abs(speed-impulse_std/friction_std) / turn_reduction_factor, 1.0)
		pitch_modifier /= turn_reduction
		roll_modifier /= turn_reduction
		yaw_modifier /= turn_reduction
	
	# Get pitch
	pitch_input = lerp(pitch_input,
		(im.up_down1*pitch_std + im.up_down2*pitch_std_right_stick) * pitch_modifier,
		lerp_strength*delta)
	
	# Get Roll
	# Right stick's roll is not affected by roll modifiers
	roll_input = lerp(roll_input,
		(im.left_right1*roll_std_left_stick + im.left_right2*roll_std_right_stick) * roll_modifier,
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
	elif is_accelerating:
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
