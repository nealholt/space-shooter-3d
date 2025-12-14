class_name NPCCapitalShipController extends CharacterBodyControlParent

# This script is based on (and has a lot of overlap with)
# npc_state_controller.gd.

@onready var target_selector := $TargetSelector
# Reference to an intermediate script through which
# states and the npc moved by the state can communicate.
@onready var movement_profile := $MovementProfile
@onready var orbit_state := $OrbitState

# Within this angle of the target, the NPC
# will start shooting
@export var shooting_angle_degrees := 10.0 # degrees
var shooting_angle:float

# Modifiers for movement amount
@export var speed: float = 70.0 ## z axis speed. Forward / backward
@export var x_speed: float = 0.0 ## Left / right speed.
@export var y_speed: float = 0.0 ## Up / down speed.
@export var pitch_amt: float = 0.8
@export var roll_amt: float = 0.8
@export var yaw_amt: float = 0.1

@export var speed_lerp: float = 10.0
@export var lerp_str: float = 3.0 # for turning

@export var target_capital_ships : bool = false

# Ideal attack distance squared
@export var ideal_distance := 450.0
# Distance at which to reduce speed as we ease toward
# ideal attack distance
@export var ease_dist := 300.0 # Squared for efficiency
@export var keep_target_above:bool = false ## Default is to orient so target is ahead, but some capital ships want their target above


func _ready() -> void:
	shooting_angle = deg_to_rad(shooting_angle_degrees)
	orbit_state.keep_target_above = keep_target_above
	orbit_state.ideal_distance_sqd = ideal_distance * ideal_distance
	orbit_state.ease_dist_sqd = ease_dist * ease_dist
	orbit_state.motion = movement_profile
	# Tell target selector to prefer capital ships
	target_selector.prefer_capital_ships = target_capital_ships


func move_and_turn(mover, delta:float) -> void:
	var gun:Gun = mover.get_current_gun()
	# Update profile.orientation_data ...
	if target and is_instance_valid(target):
		# ... to shoot the main gun at the target ...
		if gun:
			movement_profile.orientation_data.update_data(
				mover.global_position, gun.bullet_speed,
				target, mover.global_transform.basis)
		# ... but if there is no main gun, as with some
		# capital ships, we still want to move toward the target
		else:
			movement_profile.orientation_data.update_data(
				mover.global_position, speed,
				target, mover.global_transform.basis)
	# steer the craft
	orbit_state.Physics_Update(delta)
	# Move
	# Lerp toward desired settings
	pitch_input = lerp(pitch_input, movement_profile.goal_pitch * pitch_amt, lerp_str*delta)
	roll_input = lerp(roll_input, movement_profile.goal_roll * roll_amt, lerp_str*delta)
	yaw_input = lerp(yaw_input, movement_profile.goal_yaw * yaw_amt, lerp_str*delta)
	impulse = lerp(impulse, movement_profile.goal_speed * speed, speed_lerp*delta)
	x_impulse = lerp(x_impulse, movement_profile.goal_strafe_x * x_speed, speed_lerp*delta)
	y_impulse = lerp(y_impulse, movement_profile.goal_strafe_y * y_speed, speed_lerp*delta)
	
	ballistic = movement_profile.ballistic
	
	# Call parent class method
	super.move_and_turn(mover, delta)


func select_target(targeter:Node3D) -> void:
	# Get target from the target selector
	target = target_selector.get_target(targeter)


func shoot(shooter, delta:float) -> void:
	var gun = shooter.get_current_gun()
	# Decide whether or not to fire
	if gun and target and is_instance_valid(target) and movement_profile.orientation_data.dist_sqd < gun.range_sqd and Global.get_angle_to_target(shooter.global_position,target.global_position, -shooter.global_transform.basis.z) < shooting_angle:
		gun.shoot(shooter, target)
	if shooter.missile_lock:
		shooter.missile_lock.update(shooter, delta)

# Override parent class function
func enter_death_animation() -> void:
	pass
