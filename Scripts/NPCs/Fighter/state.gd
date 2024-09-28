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

# Store npc and target info
var my_pos:Vector3
var target_pos:Vector3
var dist_sqd:float
var basis
# Angles to target in radians
var x_angle:float
var y_angle:float
var z_angle:float
# Booleans for target position relative to npc
var target_is_ahead:bool
var target_is_above:bool
var target_is_right:bool
# Magnitude in indicated direction, in radians
var amt_ahead_behind:float # zero is max ahead. pi (180) is max behind
var amt_above_below:float # zero is inbetween. pi/2 (90) is max above or below
var amt_right_left:float # zero is inbetween. pi/2 (90) is max right or left

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

func update_data() -> void:
	my_pos = motion.npc.global_position
	target_pos = motion.npc.target_pos
	dist_sqd = motion.npc.distance_to_target_sqd
	basis = motion.npc.global_transform.basis
	# Calculate angles to target in radians
	y_angle = Global.get_angle_to_target(my_pos, target_pos, basis.y)
	z_angle = Global.get_angle_to_target(my_pos, target_pos, -basis.z)
	x_angle = Global.get_angle_to_target(my_pos, target_pos, basis.x)
	# Simpler angles to target
	target_is_ahead = abs(z_angle) < PI/2
	target_is_above = abs(y_angle) < PI/2
	target_is_right = abs(x_angle) < PI/2
	# Get magnitude in the direction in radians
	amt_ahead_behind = z_angle # 0 is dead ahead. pi is directly behind
	amt_above_below = abs(PI/2 - abs(y_angle)) # pi/2 is directly above or below. 0 is inbetween
	amt_right_left = abs(PI/2 - abs(x_angle)) # pi/2 is directly right or left. 0 is inbetween
