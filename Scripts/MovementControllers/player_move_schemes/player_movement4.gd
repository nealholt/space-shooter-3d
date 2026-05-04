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
#     Pitch, roll, yaw maxes out at default speed.
#     I lowered friction from 0.99 (which was misleading because
# it's also getting multiplied by delta which is typically 1/60)
# to 0.8 to get a "driftier" feel. Zero is full ballistic
# "asteroids" controls.
#     No brakes (EXCEPT WE KEPT THEM IN FOR TESTING PURPOSES)

# Stats while no inputs are given
var stats_standard:ControllerStats
# Stats while braking
@export var stats_brake:ControllerStats
# Stats while accelerating
@export var stats_accel:ControllerStats
# Stats while drifting
@export var stats_drift:ControllerStats

# Strength of movements for the right stick. This is
# an experiment to fly with both sticks.
var roll_std_right_stick: float = 2.0
var pitch_std_right_stick: float = 0.4
#Standard air friction and forward impulse
var friction_std: float = 0.8 # Lower is closer to "asteroids" controls

# Scaling factor for reducing turn rate as a function of speed
# The smaller this number is, the more turn rate will be
# reduced at high speed.
# If turn_reduction_factor is 10, then every 10 difference
# between speed and default speed will divide turn rate by 1 more.
var turn_reduction_factor:float = 40.0

var is_dead := false

var im : InputManager


func _ready() -> void:
	# Get a backup reference to the default settings
	stats_standard = stats
	impulse = stats.impulse
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
	
	#Brake
	if im.brake:
		stats = stats_brake
	#Accelerate
	elif im.accelerate:
		stats = stats_accel
	#Drift
	elif im.drift:
		stats = stats_drift
	else:
		stats = stats_standard
	
	# Lerp current impulse toward goal impulse.
	# If you lerp more than 100% weird bad behavior occurs.
	# Use min to avoid this.
	impulse = lerp(impulse, stats.impulse,
			min(1.0, stats.impulse_lerp*delta))
	
	# Calculate reduced turn rate based on difference
	# between current speed and default speed.
	var pitch_modifier: float = 1.0
	var roll_modifier: float = 1.0
	var yaw_modifier: float = 1.0
	# Don't apply if drifting.
	if !im.drift:
		var speed:float = mover.velocity.length()
		var turn_reduction:float = max(abs(speed-stats.impulse/friction_std) / turn_reduction_factor, 1.0)
		pitch_modifier /= turn_reduction
		roll_modifier /= turn_reduction
		yaw_modifier /= turn_reduction
	
	# If you lerp more than 100% weird bad behavior occurs.
	# Use min to avoid this.
	# Get pitch
	pitch_input = lerp(pitch_input,
		(im.up_down1*stats.pitch + im.up_down2*pitch_std_right_stick) * pitch_modifier,
		min(1.0, stats.turning_lerp*delta))
	# Get Roll
	roll_input = lerp(roll_input,
		(im.left_right1*stats.roll + im.left_right2*roll_std_right_stick) * roll_modifier,
		min(1.0, stats.turning_lerp*delta))
	# Get yaw using same left stick input as roll
	yaw_input = lerp(yaw_input,
		im.left_right1*stats.yaw * yaw_modifier,
		min(1.0, stats.turning_lerp*delta))
	
	friction = stats.friction_std
	
	super.move_and_turn(mover, delta)


# Override parent class function
func shoot(shootDat:ShootData, delta:float) -> void:
	if is_dead:
		return
	
	var shooter = shootDat.shooter
	if is_instance_valid(target):
		shootDat.target = target
	shootDat.bullet_speed = shooter.weapon_handler.get_bullet_speed()
	# Aim assist
	shootDat.determine_aim_assist(1)
	
	# Trigger pulled. Try to shoot.
	if shooter.weapon_handler:
		if shooter.weapon_handler.is_automatic():
			if im.shoot_pressed:
				shooter.weapon_handler.shoot(shootDat)
		else: # Semiautomatic
			if im.shoot_just_pressed:
				shooter.weapon_handler.shoot(shootDat)
	
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
	if is_dead: return
	if !im.retarget_just_pressed: return
	
	if im.use_mouse_and_keyboard:
		# Target most central enemy team member
		# based on where the mouse is looking.
		select_target_from_mouse(targeter)
	else:
		# Target most central enemy team member
		select_target_screen_center(targeter)


func misc_actions(actor) -> void:
	if im.switch_weapons:
		actor.weapon_handler.change_weapon()


# Override parent class function
func enter_death_animation() -> void:
	is_dead = true
