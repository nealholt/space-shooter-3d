class_name PlayerController5 extends CharacterBodyControlParent

# When drift is just released, lerp heading
# toward velocity for this duration.
@export var heading_reset_duration:float = 1.0 ## Seconds
var heading_reset_countdown:float = 0.0
@export var heading_reset_strength:float = 5.0

# Stats while no inputs are given
var stats_standard:ControllerStats
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

var im : InputManager


func _ready() -> void:
	# Get a backup reference to the default settings
	stats_standard = stats
	impulse = stats.impulse
	im = Global.input_man


# Override parent class function
func move_and_turn(mover, delta:float) -> void:
	if is_dead:
		return
	
	im.update()
	
	# If drift is just released, lerp heading toward
	# velocity for the next heading_reset_duration
	# seconds.
	# The idea is to use drift to do strafing attacks,
	# but NOT to change direction.
	if im.drift_just_released:
		heading_reset_countdown = heading_reset_duration
	if heading_reset_countdown > 0.0:
		heading_reset_countdown -= delta
		# lerp heading toward velocity
		var target:Vector3 = mover.global_position + mover.velocity
		mover.transform = Global.interp_face_target(mover, target, delta*heading_reset_strength)
		# If you don't like the yaw, you might rewrite
		# this to steer like an NPC's seek function
	
	#Brake
	#if im.brake:
		#pass # TODO LEFT OFF HERE
	#Accelerate
	if im.accelerate:
		stats = stats_accel
	#Drift
	elif im.drift:
		stats = stats_drift
		# Drifting cancels heading reset
		heading_reset_countdown = 0.0
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
		var turn_reduction:float = max(abs(speed-stats.impulse/stats.friction_std) / turn_reduction_factor, 1.0)
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
