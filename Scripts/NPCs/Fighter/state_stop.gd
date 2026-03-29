class_name StateStop extends State

# It's mandatory that each state implement this otherwise
# abstract function, but since the motion parameters
# are all reset to zero when entering a state, there's
# nothing else to really do for the stop state.
func Physics_Update(_delta:float) -> void:
	pass
