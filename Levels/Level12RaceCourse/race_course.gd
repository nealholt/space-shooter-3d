class_name RaceCourse extends Level

@onready var checkpoints: Node3D = $Checkpoints
var gate_index:int = -1
var time_to_3_stars:float = 90.0
var time_to_2_stars:float = 120.0
var time_to_1_star:float = 240.0


func _ready() -> void:
	super._ready()
	# Activate first gate
	checkpoint_reached()

func checkpoint_reached() -> void:
	# Advance to next gate
	gate_index += 1
	# If final gate reached, you win!
	if gate_index >= checkpoints.get_child_count():
		# Update elapsed time on the end screen / Victory Layer
		end_screen.time_label.text = 'Elapsed Time '+get_elapsed_time()
		# Award stars
		var awards:Array[bool] = [
			elapsed_time < time_to_1_star,
			elapsed_time < time_to_2_stars,
			elapsed_time < time_to_3_stars
		]
		end_screen.victory(awards)
		return
	# Get next gate
	var gate:CheckPoint = checkpoints.get_child(gate_index)
	# Activate next gate
	gate.activate_checkpoint.call_deferred()
	# Connect to signal from next gate
	gate.reached.connect(checkpoint_reached)	
