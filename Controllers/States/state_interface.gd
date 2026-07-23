@abstract
class_name State extends Node
# Finite state machine source:
# https://www.youtube.com/watch?v=ow_Lum-Agbs&t=145s

signal Transitioned(s:State, str:String)
# Added so the debugger stops nagging me.
# This signal is emitted by the attack state.
@warning_ignore("unused_signal")
signal NewTargetRequested

# Random number generator
var random := RandomNumberGenerator.new()

# Elapsed time in this state (Not used by all states)
var elapsed_time:float
# Time limit for this state (Not used by all states)
var time_limit:float

# This is just 90 degrees in radians for efficiency/readability
const ninety_degrees:float = PI/2.0

var in_death_animation:bool = false

var obstacle_detector:ObstacleDetector


func _on_ready() -> void:
	# Feed a time-based seed to the RNG.
	random.randomize()

# This function should contain code to be
# executed at the start of the state,
# including any set up that needs performed.
func Enter(_motion:MovementProfile) -> void:
	elapsed_time = 0.0

# This function should contain code to be
# executed at the end of the state,
# including any clean up that needs performed.
func Exit(_motion:MovementProfile) -> void:
	pass

# This function should be called on each
# physics update frame.
@abstract func Physics_Update(_delta:float, _motion:MovementProfile, _orientation_data:TargetOrientationData) -> void


func enter_death_animation() -> void:
	if !in_death_animation:
		Transitioned.emit(self, 'deathanimation')
		in_death_animation = true


func transition_to_evasion() -> void:
	# If not in the death animation...
	if !in_death_animation:
		# ...then switch into evasion state.
		var x := random.randi() % 3
		if x == 0:
			Transitioned.emit(self, 'jink')
		elif x == 1:
			Transitioned.emit(self, 'wave')
		else:
			Transitioned.emit(self, 'corkscrew')


func avoid_now() -> void:
	Transitioned.emit(self, 'avoid')


# Returns one or negative one randomly
func _one_or_neg_one() -> int:
	if random.randi()%2 == 0:
		return 1.0
	else:
		return -1.0
