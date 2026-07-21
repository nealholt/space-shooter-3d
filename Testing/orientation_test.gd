extends Node

@export var pov:Array[Ship]
@export var other:Array[Ship]
@export var cam:Array[Camera3D]
var scenario:Array[String] = \
	['Scenario 1: Target dead ahead, facing away from me.',
	'Scenario 2: Target facing me from behind.',
	'Scenario 3: Head to head.',
	'Scenario 4: Mostly head to head. I\'m tilted up 45 degrees',
	'Scenario 5: Target facing me from above',
	'Scenario 6: Target facing away from above',
	'Scenario 7: Target facing me from right',
	'Scenario 8: Target facing away on right']
var index := -1

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set to windowed, not full screen
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# Display instructions
	print('Press space bar to advance to next test')
	print('Press escape to exit')
	
	for i in pov.size():
		# Don't let pov ships shoot. It will cause errors.
		pov[i].controller.dont_shoot = true
		# Set pov ship to target corresponding other ship
		pov[i].controller.set_target(pov[i], other[i].hit_box_component)


func _unhandled_input(event) -> void:
	if !(event is InputEventKey): return
	if !event.pressed: return
	# Escape to quit
	if event.keycode == KEY_ESCAPE:
		get_tree().quit()
	# Space bar to advance to next test
	elif event.keycode == KEY_SPACE:
		# Advance to the next scenario
		index = (index+1) % pov.size()
		cam[index].make_current()
		print()
		print(scenario[index])
		pov[index].controller.orientation_data.print_data()
