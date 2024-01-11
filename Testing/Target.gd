extends Node3D

var speed := 3.0
var time_tracker := 0.0
var time_limit := 3.0 #seconds
var state := 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if state == 1:
		global_position.x += delta * speed
	if state == 2:
		global_position.x -= delta * speed
	if state == 3:
		global_position.z -= delta * speed*1.2
	if state == 4:
		global_position.y += delta * speed
	if state == 5:
		global_position.y -= delta * speed*2.2
	
	time_tracker += delta
	if time_tracker > time_limit:
		state += 1
		time_tracker = 0.0
