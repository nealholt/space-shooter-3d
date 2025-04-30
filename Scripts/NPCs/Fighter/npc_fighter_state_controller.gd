extends CharacterBodyControlParent
class_name NPCFighterStateMachine

# This script handles basic transitioning between states
# and an extreme check that sends the ship toward the
# origin if the ship goes way out of bounds.

# Source:
# https://www.youtube.com/watch?v=ow_Lum-Agbs&t=300s

@onready var target_selector := $TargetSelector

# Reference to an intermediate script through which
# states and the npc moved by the state can communicate.
@export var movement_profile : MovementProfile

@export var initial_state : State
var current_state : State
var states : Dictionary = {}

# Within this angle of the target, the enemy
# will start shooting
@export var shooting_angle_degrees := 10.0 # degrees
var shooting_angle:float

# Modifiers for movement amount
@export var speed: float = 70.0
@export var pitch_amt: float = 0.8
@export var roll_amt: float = 0.8
@export var yaw_amt: float = 0.1

@export var speed_lerp: float = 10.0
@export var lerp_str: float = 3.0 # for turning

@export var target_capital_ships : bool = false

# I'm anxious about the wisdom of adding variables
# here that just set lower level variables in the
# states, but for now, this is the best I've come
# up with.
@export var too_far:float = 150.0 ## Distance at which to come in for another attack pass
@export var too_close:float = 30.0 ## Distance at which to stop attack pass and peel off


func _ready() -> void:
	shooting_angle = deg_to_rad(shooting_angle_degrees)
	#print('In StateMachine _ready adding children:')
	for child in $States.get_children():
		if child is State:
			#print(child.name.to_lower())
			states[child.name.to_lower()] = child
			child.Transitioned.connect(on_child_transition)
			child.motion = movement_profile
	if initial_state:
		initial_state.Enter()
		current_state = initial_state
	# Tell target selector to prefer capital ships
	target_selector.prefer_capital_ships = target_capital_ships
	# Set state parameters. Squared for efficiency.
	$States/Seek.too_close_sqd = too_close * too_close
	$States/Flee.distance_limit_sqd = too_far * too_far


func move_and_turn(mover, delta:float) -> void:
	var gun:Gun = mover.get_current_gun()
	# Update profile.orientation_data
	if gun and target and is_instance_valid(target):
		movement_profile.orientation_data.update_data(
			mover.global_position, gun.bullet_speed,
			target, mover.global_transform.basis)
	# Update the current state, which updates
	# the movement profile, which is used below
	# to steer the craft
	if current_state:
		current_state.Physics_Update(delta)
	# Move
	# Lerp toward desired settings
	pitch_input = lerp(pitch_input, movement_profile.goal_pitch * pitch_amt, lerp_str*delta)
	roll_input = lerp(roll_input, movement_profile.goal_roll * roll_amt, lerp_str*delta)
	yaw_input = lerp(yaw_input, movement_profile.goal_yaw * yaw_amt, lerp_str*delta)
	impulse = lerp(impulse, movement_profile.goal_speed * speed, speed_lerp*delta)
	
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


func on_child_transition(state, new_state_name):
	if state != current_state:
		#print('in state machine state != current_state')
		return
	
	var new_state = states.get(new_state_name.to_lower())
	if !new_state:
		#print('in state machine !new_state')
		return
	
	if current_state:
		current_state.Exit()
	
	new_state.Enter()
	
	current_state = new_state

# Override parent class function
func took_damage() -> void:
	go_evasive()

func go_evasive() -> void:
	current_state.choose_random_evasion()

# Override parent class function
func enter_death_animation() -> void:
	current_state.enter_death_animation()

# Override parent class function
# Died implies that the death animation has concluded.
func died(who_died) -> void:
	# NPC died, so queue free it at the end of the frame
	Callable(who_died.queue_free).call_deferred()
