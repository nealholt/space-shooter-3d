class_name NPCController extends CharacterBodyControlParent

# This script handles basic transitioning between states
# and an extreme check that sends the ship toward the
# origin if the ship goes way out of bounds.

# Source:
# https://www.youtube.com/watch?v=ow_Lum-Agbs&t=300s

@onready var target_selector := $TargetSelector

# Reference to an intermediate script through which
# states and the npc moved by the state can communicate.
@onready var movement_profile := $MovementProfile

@export var initial_state : State
var current_state : State
var states : Dictionary = {}

# Within this angle of the target, the enemy
# will start shooting
@export_range(0, 90, 0.1, "radians_as_degrees") var angle_to_shoot: float = deg_to_rad(2.0)

# Modifiers for movement amount
@export var x_speed: float = 0.0 ## Left / right speed.
@export var y_speed: float = 0.0 ## Up / down speed.

@export var target_capital_ships : bool = false

# THESE ARE NOT CAPITAL SHIP VARIABLES.
# I'm anxious about the wisdom of adding variables
# here that just set variables in child state
# nodes, but for now, this is the best I've come
# up with.
@export var too_far:float = 600.0 ## Distance at which to come in for another attack pass
@export var too_close:float = 100.0 ## Distance at which to stop attack pass and peel off
@export var keep_target_above:bool = false ## Default is to orient so target is ahead, but some capital ships want their target above

# Setting the following to true will cause the fighter label to
# show the current state.
@export var DEBUG : bool = false #TESTING
var debug_label:Label3D

@export var dont_shoot:bool = false #TESTING

# Distance at which to reduce speed as we ease toward
# ideal attack distance. This is currently only used
# by capital ships.
@export var ease_dist := 300.0 # Squared for efficiency

# When this flag is set, update to a new target at the
# first opportunity. The new target might be the same
# target, but only if it meets the targeting criteria,
# which has been the most central hitbox in view, but
# maybe I got around to updating it.
var target_update_requested:bool = false

# Object containing data to orient on target.
# Is accessed by the states.
var orientation_data:TargetOrientationData


func _ready() -> void:
	super._ready()
	orientation_data = TargetOrientationData.new()
	# Tell target selector to prefer capital ships
	target_selector.prefer_capital_ships = target_capital_ships
	#print('In StateMachine _ready adding children:')
	for child in $States.get_children():
		if child is State:
			#print(child.name.to_lower())
			states[child.name.to_lower()] = child
			child.Transitioned.connect(on_child_transition)
			# Connect to signal
			child.NewTargetRequested.connect(_on_target_update_request)
	if initial_state:
		movement_profile.reset()
		initial_state.Enter(movement_profile)
		current_state = initial_state
	# Set state parameters. Squared for efficiency.
	$States/Attack.too_close_sqd = too_close * too_close
	$States/GoTo.too_close_sqd = too_close * too_close
	$States/Flee.distance_limit_sqd = too_far * too_far
	var ideal_distance:float = (too_far + too_close) / 2.0
	var orbit_state:State = $States/Orbit
	orbit_state.ideal_distance_sqd = ideal_distance * ideal_distance
	orbit_state.keep_target_above = keep_target_above
	orbit_state.ease_dist_sqd = ease_dist * ease_dist
	#TESTING
	if DEBUG:
		var p:Node3D = get_parent()
		for c in p.get_children():
			if c is Label3D:
				debug_label = c
				c.visible = true
				break


func set_obstacle_detector(obstacle_detector:ObstacleDetector) -> void:
	# Give every state a reference to the obstacle detector
	for state_key:String in states:
		var state:State = states[state_key]
		state.obstacle_detector = obstacle_detector


func move_and_turn(mover:Ship, delta:float) -> void:
	var gun:Gun = mover.get_current_gun()
	# Update orientation_data ...
	if is_instance_valid(target):
		# ... to shoot the main gun at the target ...
		# Default to using ship speed
		var temp_speed:float = mover.velocity.length()
		# But if there is a gun, we want to lead the
		# target using bullet speed.
		if gun:
			temp_speed = gun.bullet_speed
		# Update orientation_data
		orientation_data.update_data(
			mover.global_position, temp_speed,
			target, mover.global_transform.basis)
	# Update the current state, which updates
	# the movement profile, which is used below
	# to steer the craft
	if current_state:
		current_state.Physics_Update(delta, movement_profile, orientation_data)
	# Move
	# Lerp toward desired settings
	# The 1-exp is for frame rate independent lerp. This is
	# Freya Holmer lerp smoothing.
	pitch_input = lerp(pitch_input, movement_profile.goal_pitch * stats.pitch, 1.0-exp(-delta * stats.turning_lerp))
	roll_input = lerp(roll_input, movement_profile.goal_roll * stats.roll, 1.0-exp(-delta * stats.turning_lerp))
	yaw_input = lerp(yaw_input, movement_profile.goal_yaw * stats.yaw, 1.0-exp(-delta * stats.turning_lerp))
	impulse = lerp(impulse, movement_profile.goal_speed * stats.impulse, 1.0-exp(-delta * stats.impulse_lerp))
	x_impulse = lerp(x_impulse, movement_profile.goal_strafe_x * x_speed, 1.0-exp(-delta * stats.impulse_lerp))
	y_impulse = lerp(y_impulse, movement_profile.goal_strafe_y * y_speed, 1.0-exp(-delta * stats.impulse_lerp))
	
	# Call parent class method
	super.move_and_turn(mover, delta)


func select_target(targeter:Ship) -> void:
	# If the target died or a target update was requested,
	# set a new target
	if !is_instance_valid(target) or target_update_requested:
		# Get target from the target selector
		set_target(targeter, target_selector.update_target(targeter))
		target_update_requested = false


func shoot(shoot_dat:ShootData) -> void:
	if dont_shoot: return
	if !is_instance_valid(target): return
	
	var shooter:Ship = shoot_dat.shooter
	
	# Don't shoot if line of sight is blocked by an ally.
	# Check for line of sight on target
	var los:bool = RayOnDemand.me.line_is_clear(shooter.global_position, target.global_position, target)
	# If line of sight is blocked...
	if !los:
		# Get obstacle
		var blocker:CollisionObject3D = RayOnDemand.me.get_obstacle()
		# If the obstacle is not our target, lose missile lock progress
		if blocker != target.get_parent():
			line_of_sight_lost.emit()
		# If line of sight is blocked by an ally, abort
		if 'ally_team' in blocker and ally_team == blocker.ally_team:
			return
	
	# GUNS:
	# If shooter has a target and a weapon handler, then proceed
	# to a decision whether or not to shoot
	if !is_instance_valid(target) or !shooter.weapon_handler:
		return
	shoot_dat.target = target
	# Decide whether or not to fire
	if orientation_data.dist_sqd < shoot_dat.gun.range_sqd \
	and Global.get_angle_to_target(shooter.global_position,target.global_position, -shooter.global_transform.basis.z) < angle_to_shoot:
		shoot_dat.shoot()


func on_child_transition(state:State, new_state_name:String) -> void:
	if state != current_state:
		#print('in state machine state != current_state')
		return
	
	var new_state:State = states.get(new_state_name.to_lower())
	if !new_state:
		print('In npc_controller. No state named ', new_state_name)
		return
	
	if current_state:
		current_state.Exit(movement_profile)
	
	movement_profile.reset()
	new_state.Enter(movement_profile)
	
	current_state = new_state
	
	#TESTING
	if DEBUG and debug_label:
		debug_label.text = new_state_name.to_lower()

# Override parent class function
# amount is the amount of health lost.
# ship.gd connects health_lost signal to this function
func took_damage(_health:HealthComponent, _amount:float) -> void:
	# If we are in an interruptable state, interrupt it
	# and transition to evasion.
	if movement_profile.can_interrupt_state:
		current_state.transition_to_evasion()

# Override parent class function
func enter_death_animation() -> void:
	current_state.enter_death_animation()
	# Go ballistic. No "air" friction.
	friction = 0.0

func _on_target_update_request() -> void:
	target_update_requested = true
