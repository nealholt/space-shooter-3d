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

# Scaling factor for reducing turn rate as a function of speed
# The smaller this number is, the more turn rate will be
# reduced at high speed.
# If turn_reduction_factor is 10, then every 10 difference
# between speed and default speed will divide turn rate by 1 more.
# The practical effect of this is that you can't turn sharply
# immediately just because you let off the accelerator.
# You have to wait until your speed goes back down.
# I'm not sure I like this much. Higher values essentially
# make this meaningless.
# The initial impetus was to do something like X-Wing
# where the best turn rate is at 1/3 max velocity.
@export_range(1,5000, 10) var turn_reduction_factor:float = 100.0

var is_dead := false

# Reference to engine audiovisuals. ship.gd is responsible for
# setting up this reference.
var engineAV:EngineAV


func _ready() -> void:
	# Get a backup reference to the default settings
	stats_standard = stats
	impulse = stats.impulse


# Update every physics frame. This is called from ship
func Update(ship:Ship, delta:float) -> void:
	# Make sure to update the inputs before any further action
	InputManager.im.update()
	super.Update(ship, delta)


# Override parent class function
func move_and_turn(mover:Ship, delta:float) -> void:
	if is_dead: return
	
	#Brake
	if InputManager.im.brake:
		stats = stats_brake
		engineAV.shift2brake(0.0)
	#Accelerate
	elif InputManager.im.accelerate:
		stats = stats_accel
		engineAV.shift2afterburners(4.0)
	#Drift
	elif InputManager.im.drift:
		stats = stats_drift
		engineAV.shift2drift(1.0)
	else:
		stats = stats_standard
		engineAV.shift2default(2.0)
	
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
	if !InputManager.im.drift:
		var speed:float = mover.velocity.length()
		var turn_reduction:float = max(abs(speed-stats.impulse/stats.friction_std) / turn_reduction_factor, 1.0)
		pitch_modifier /= turn_reduction
		roll_modifier /= turn_reduction
		yaw_modifier /= turn_reduction
	
	# If you lerp more than 100% weird bad behavior occurs.
	# Use min to avoid this.
	# Get pitch
	pitch_input = lerp(pitch_input,
		(InputManager.im.up_down1*stats.pitch + InputManager.im.up_down2*pitch_std_right_stick) * pitch_modifier,
		min(1.0, stats.turning_lerp*delta))
	# Get Roll
	roll_input = lerp(roll_input,
		(InputManager.im.left_right1*stats.roll + InputManager.im.left_right2*roll_std_right_stick) * roll_modifier,
		min(1.0, stats.turning_lerp*delta))
	# Get yaw using same left stick input as roll
	yaw_input = lerp(yaw_input,
		InputManager.im.left_right1*stats.yaw * yaw_modifier,
		min(1.0, stats.turning_lerp*delta))
	
	friction = stats.friction_std
	
	super.move_and_turn(mover, delta)


# Override parent class function
func shoot(shooter:Ship, delta:float) -> void:
	if is_dead:
		return
	# GUNS:
	# If shooter has a weapon handler...
	if shooter.weapon_handler:
		var gun:Gun = shooter.weapon_handler.current_weapon
		# Construct the shoot data. Even though we might not
		# shoot, the aim assist below needs this in order to
		# know whether or not to play the audio cue.
		var shootDat:ShootData = shooter.get_new_shootdata()
		if is_instance_valid(target):
			shootDat.target = target
		shootDat.gun = gun
		shootDat.bullet_speed = gun.bullet_speed
		shootDat.determine_aim_assist(1)
		# ...and an automatic weapon is selected and shoot is pressed
		# or a semiauto weapon is selected and shoot was just pressed,
		# then shoot.
		if (gun.automatic and InputManager.im.shoot_pressed) or (!gun.automatic and InputManager.im.shoot_just_pressed):
			gun.shoot(shootDat)
	
	# MISSILES:
	# If shooter has a missile lock component...
	if shooter.missile_lock:
		var mlg:MissileLockGroup = shooter.missile_lock
		# Target most centered enemy and begin missile lock
		if InputManager.im.retarget_just_pressed:
			mlg.attempt_to_start_seeking(shooter)
		# Fire missile if lock is acquired
		elif InputManager.im.retarget_just_released:
			mlg.attempt_to_fire_missile(shooter)
		# Update the missile lock group component
		mlg.update(shooter, delta)


# Override parent class function
func select_target(targeter:Node3D) -> void:
	if is_dead: return
	if !InputManager.im.retarget_just_pressed: return
	if InputManager.im.use_mouse_and_keyboard:
		# Target most central enemy team member
		# based on where the mouse is looking.
		select_target_from_mouse(targeter)
	else:
		# Target most central enemy team member
		select_target_screen_center(targeter)


func misc_actions(actor) -> void:
	if InputManager.im.switch_weapons:
		actor.weapon_handler.change_weapon()


# Override parent class function
func enter_death_animation() -> void:
	is_dead = true
