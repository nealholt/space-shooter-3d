extends Node
class_name StateMachine
# Source:
# https://www.youtube.com/watch?v=ow_Lum-Agbs&t=300s

# If any npc moves beyond square root of distance_limit_sqd
# then they should be forced into the goto state
# with destination set as origin.
var distance_limit_sqd := 100000.0**2 # 100,000^2

# Reference to an intermediate script through which
# states and the npc moved by the state can communicate.
@export var movement_profile : MovementProfile

@export var initial_state : State
var current_state : State
var states : Dictionary = {}

func _ready() -> void:
	#print('In StateMachine _ready adding children:') # TESTING
	for child in get_children():
		if child is State:
			#print(child.name.to_lower()) # TESTING
			states[child.name.to_lower()] = child
			child.Transitioned.connect(on_child_transition)
			child.motion = movement_profile
	if initial_state:
		initial_state.Enter()
		current_state = initial_state

func _process(delta: float) -> void:
	if current_state:
		current_state.Update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.Physics_Update(delta)

func on_child_transition(state, new_state_name):
	# Check if npc is beyond distance limit from origin
	if movement_profile.npc.global_position.distance_squared_to(Vector3.ZERO) > distance_limit_sqd:
		# Force NPC to goto origin
		new_state_name = "goto"
		$GoTo.destination = Vector3.ZERO
		$GoTo.too_close_sqd = 1000.0**2
	
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
	# TESTING DEBUGGING
	$"../DebugLabel".text = new_state_name
	

func go_evasive() -> void:
	current_state.choose_random_evasion()
