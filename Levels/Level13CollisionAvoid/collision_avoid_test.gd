extends Level
# This is just a copy of the level.gd script with a little extra
# to be able to tap the test ship with a bit of damage to see
# how it responds.

@onready var observed_ship: Ship = $RedTeam/Fighter

func _ready() -> void:
	super()
	print('Press space bar to tap the observed ship with a bit of damage')

func _unhandled_input(event: InputEvent) -> void:
	if !(event is InputEventKey): return
	if !event.pressed: return
	## Escape to quit
	#if event.keycode == KEY_ESCAPE:
		#get_tree().quit()
	# Space bar to advance to next test
	elif event.keycode == KEY_SPACE:
		print('Ship damaged')
		observed_ship.health_component.health -= 1
