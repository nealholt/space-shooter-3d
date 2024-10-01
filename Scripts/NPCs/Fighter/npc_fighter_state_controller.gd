extends CharacterBodyControlParent
class_name NPCFighterStateMachine

# This script handles basic transitioning between states
# and an extreme check that sends the ship toward the
# origin if the ship goes way out of bounds.

# Source:
# https://www.youtube.com/watch?v=ow_Lum-Agbs&t=300s

# Reference to an intermediate script through which
# states and the npc moved by the state can communicate.
@export var movement_profile : MovementProfile

@export var initial_state : State
var current_state : State
var states : Dictionary = {}

var ally_team:String
var enemy_team:String

# Within this angle of the target, the enemy
# will start shooting
@export var shooting_angle := deg_to_rad(10.0) # degrees (immediately converted to radians)

# Modifiers for movement amount
@export var speed: float = 40.0*60.0 # 40.0 meters per second
@export var pitch_amt: float = 0.8
@export var roll_amt: float = 0.8
@export var yaw_amt: float = 0.1

# Parameters for lerping the amount of roll, pitch,
# yaw, and speed.
var pitch_str: float = 0.0
var roll_str: float = 0.0
var yaw_str: float = 0.0
var current_speed: float = 0.0

@export var speed_lerp: float = 10.0
@export var lerp_str: float = 3.0 # for turning

# Whether or not the controlled ship should try to fire
var firing:bool = false


func _ready() -> void:
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


func move_and_turn(mover, delta:float) -> void:
	var gun:Gun = mover.get_current_gun()
	# Get target from the target selector
	var target = $TargetSelector.get_target(mover)
	# Update profile.orientation_data
	if target:
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
	pitch_str = lerp(pitch_str, movement_profile.goal_pitch * pitch_amt, lerp_str*delta)
	roll_str = lerp(roll_str, movement_profile.goal_roll * roll_amt, lerp_str*delta)
	yaw_str = lerp(yaw_str, movement_profile.goal_yaw * yaw_amt, lerp_str*delta)
	current_speed = lerp(current_speed, movement_profile.goal_speed * speed, speed_lerp*delta)
	# Pitch
	mover.transform.basis = mover.transform.basis.rotated(mover.transform.basis.x, pitch_str * delta)
	# Roll
	mover.transform.basis = mover.transform.basis.rotated(mover.transform.basis.z, roll_str * delta)
	# Yaw
	mover.transform.basis = mover.transform.basis.rotated(mover.transform.basis.y, yaw_str * delta)
	# Update velocity
	mover.velocity = -mover.transform.basis.z * current_speed * delta
	# Move straight ahead
	mover.move_and_slide()
	# Decide whether or not to fire
	firing = movement_profile.orientation_data.dist_sqd < gun.range_sqd && Global.get_angle_to_target(mover.global_position,target.global_position, -mover.global_transform.basis.z) < shooting_angle



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
	
	if $"../DebugLabel" and $"../DebugLabel".visible:
		$"../DebugLabel".text = new_state_name


func go_evasive() -> void:
	current_state.choose_random_evasion()
