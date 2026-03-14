class_name RaceCourse extends Level

@onready var checkpoints: Node3D = $Checkpoints
var gate_index:int = -1

func _ready() -> void:
	super._ready()
	# Activate first gate
	checkpoint_reached()

func checkpoint_reached() -> void:
	# Advance to next gate
	gate_index += 1
	# If final gate reached, you win!
	if gate_index >= checkpoints.get_child_count():
		end_screen.victory(Array())
		return
	# Get next gate
	var gate:CheckPoint = checkpoints.get_child(gate_index)
	# Activate next gate
	gate.activate_checkpoint.call_deferred()
	# Target next gate
	#TODO Use the player's targeting system to target the next gate
	# Connect to signal from next gate
	gate.reached.connect(checkpoint_reached)	
