extends Node
class_name State
# Source:
# https://www.youtube.com/watch?v=ow_Lum-Agbs&t=145s

# This class is both an interface for all states and
# also serves as the stop state.
signal Transitioned

# Reference to an intermediate script through which
# states and the npc moved by the state can communicate.
var motion : MovementProfile

# Random number generator
var random := RandomNumberGenerator.new()

# Elapsed time in this state (Not used by all states)
var elapsed_time:float
# Time limit for this state (Not used by all states)
var time_limit:float

# This is just 90 degrees in radians for efficiency/readability
const ninety_degrees:float = PI/2.0

func _on_ready() -> void:
	random.randomize()

# This function should contain code to be
# executed at the start of the state,
# any set up that needs performed.
func Enter() -> void:
	motion.reset()

# This function should contain code to be
# executed at the end of the state,
# any clean up that needs performed.
func Exit() -> void:
	motion.reset()

# This function should be called on each
# update frame.
func Update(_delta:float) -> void:
	pass

# This function should be called on each
# physics update frame.
func Physics_Update(_delta:float) -> void:
	pass # Replace with function body.

func choose_random_evasion() -> void:
	# If the current state can be interrupted...
	if motion.can_interrupt_state:
		# ...then switch into evasion state.
		var x := random.randi() % 3
		if x == 0:
			Transitioned.emit(self, 'jink')
		elif x == 1:
			Transitioned.emit(self, 'wave')
		else:
			Transitioned.emit(self, 'corkscrew')
