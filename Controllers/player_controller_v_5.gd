class_name PlayerController5 extends CharacterBodyControlParent

# It turns out I don't like the following, so I'm commenting it out for now.
# Maybe there is a different way to limit abuse
# of drift, like make it a powerup akin to gap 
# drive and put something else on the drift button?
# Alternatively, let the player abuse drift.
# If enemies shoot more accurately it might not
# even be an abusable feature.
#    -Maybe do put a brake on the current drift button, but it only slows you down a little while increasing turn rate.
#    -Maybe allow the player to drift, but the turn rate is sluggish
#    -Maybe allow the player to drift, but emerging out of it is sluggish
# When drift is just released, lerp heading
# toward velocity for this duration.
#@export var heading_reset_duration:float = 0.7 ## Seconds
#var heading_reset_countdown:float = 0.0
#@export var heading_reset_strength:float = 5.0

# Amount to lean into turns. This makes the camera rotate in the
# direction of the turn.
@export var lean_up_down:float = 0.2 ## Percent
@export var lean_left_right:float = 0.2 ## Percent

# Stats while no inputs are given
var stats_standard:ControllerStats
# Stats while accelerating
@export var stats_accel:ControllerStats
# Stats while drifting
@export var stats_drift:ControllerStats

var is_dead := false

var im : InputManager

# Reference to engine audiovisuals. ship.gd is responsible for
# setting up this reference.
var engineAV:EngineAV


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
	#if im.drift_just_released:
		#heading_reset_countdown = heading_reset_duration
	#if heading_reset_countdown > 0.0:
		#heading_reset_countdown -= delta
		## lerp heading toward velocity
		#var pos:Vector3 = mover.global_position + mover.velocity
		#mover.transform = Global.interp_face_target(mover, pos, delta*heading_reset_strength)
		# Consider rewriting the above to steer
		# like an NPC's seek function, otherwise it will
		# yaw unnaturally.
	
	#Brake
	#if im.brake:
		#pass
	#Accelerate
	if im.accelerate:
		stats = stats_accel
		engineAV.shift2afterburners(4.0)
	#Drift
	elif im.drift:
		stats = stats_drift
		engineAV.shift2drift(1.0)
		# Drifting cancels heading reset
		#heading_reset_countdown = 0.0
	else:
		stats = stats_standard
		engineAV.shift2default(2.0)
	
	# Lerp current impulse toward goal impulse.
	# If you lerp more than 100% weird bad behavior occurs.
	# Use min to avoid this.
	impulse = lerp(impulse, stats.impulse,
			min(1.0, stats.impulse_lerp*delta))
	
	# If you lerp more than 100% weird bad behavior occurs.
	# Use min to avoid this.
	# Get pitch
	pitch_input = lerp(pitch_input,
		im.up_down1 * stats.pitch,
		min(1.0, stats.turning_lerp*delta))
	# Get Roll
	roll_input = lerp(roll_input,
		im.left_right1 * stats.roll,
		min(1.0, stats.turning_lerp*delta))
	# Get yaw using same left stick input as roll
	yaw_input = lerp(yaw_input,
		im.left_right1*stats.yaw,
		min(1.0, stats.turning_lerp*delta))
	
	friction = stats.friction_std
	
	# Turn "head" and "neck"
	var manual_look:bool = im.left_right2 != 0.0 or im.up_down2 != 0.0
	Global.camera_group.set_fp_manual_override(manual_look)
	if manual_look:
		# -im.up_down2 The negative makes it be NOT inverted, which
		# makes more sense to my thumb.
		Global.camera_group.rotate_fp_cam(im.left_right2, -im.up_down2, delta)
		#print(im.left_right2)
		#print(im.up_down2)
	else:
		var lean_in:bool = im.left_right1 != 0.0 or im.up_down1 != 0.0
		Global.camera_group.set_fp_manual_override(lean_in)
		# Lean into turns
		if lean_in:
			var horz_lean:=im.left_right1*lean_left_right
			var vert_lean:=im.up_down1*lean_up_down
			Global.camera_group.rotate_fp_cam(horz_lean, vert_lean, delta)
	
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
		if (gun.automatic and im.shoot_pressed) or (!gun.automatic and im.shoot_just_pressed):
			gun.shoot(shootDat)
	
	# MISSILES:
	# If shooter has a missile lock component...
	if shooter.missile_lock:
		var mlg:MissileLockGroup = shooter.missile_lock
		# Target most centered enemy and begin missile lock
		if im.retarget_just_pressed:
			mlg.attempt_to_start_seeking(shooter)
		# Fire missile if lock is acquired
		elif im.retarget_just_released:
			mlg.attempt_to_fire_missile(shooter)
		# Update the missile lock group component
		mlg.update(shooter, delta)


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
