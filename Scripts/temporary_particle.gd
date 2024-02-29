extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start emitting all particles
	# and get the max duration
	var max_lifetime := 0.0
	for n in get_children():
		n.set_emitting(true)
		if n.lifetime > max_lifetime:
			max_lifetime = n.lifetime
	# Create timer to queue free when we're all done
	var timer := Timer.new()
	add_child(timer)
	timer.timeout.connect(self.queue_free)
	timer.start(max_lifetime)
