extends Node3D
# This is just a copy of the level.gd script with a little extra
# to be able to tap the test ship with a bit of damage to see
# how it responds.


@onready var observed_ship: Ship = $RedTeam/Fighter


var end_screen : EndScreen # aka victory_layer
var red_team : TeamSetup
var blue_team : TeamSetup

func _ready() -> void:
	print('Press space bar to tap the observed ship with a bit of damage')
	# Set up global reference to world environment
	Global.environment = $WorldEnvironment.environment
	# Emit that world environment is now set
	EventsBus.environment_set.emit()
	# Connect to signals that a ship died
	EventsBus.ship_died.connect(check_win_loss)
	# Search for an asteroid field child. If found,
	# generate the asteroid field.
	# This is done instead of using the _ready function
	# in asteroid_field.gd because the player needs
	# to be instantiated before the asteroid field.
	for c in get_children():
		if c is AsteroidField:
			c.generate_field()
		elif c is EndScreen:
			end_screen = c
		elif c is TeamSetup:
			if c.team == "red team":
				red_team = c
			else:
				blue_team = c
	# This is nice to prevent a jarring pull to the side
	# at the start of each level when mouse and keyboard
	# are in use.
	center_the_mouse()
	# Create a ray on demand and attach it as a child
	RayOnDemand.new_ray(self)


# This function is called after something dies.
func check_win_loss(dead_thing) -> void:
	# If there is no end screen or enemy team, return.
	# There's nothing to do here.
	if !(end_screen and red_team):
		return
	# If the player died. Show defeat.
	# If the entire red team died. Show victory.
	if Ship.player == dead_thing:
		end_screen.defeat()
		# Prevent reactivation of end_screen.
		EventsBus.ship_died.disconnect(check_win_loss)
	# This assumes the red team is always the enemy.
	elif red_team.get_child_count() == 0:
		end_screen.victory(Array())
	# Unfortunately since the signal is emitted from the
	# ship that died, the red_team won't actually have
	# no children yet, so we also check if there is one
	# dead child.
	elif red_team.get_child_count() == 1:
		var child:HealthComponent = red_team.get_child(0).health_component
		if child.is_dead():
			end_screen.victory(Array())


func center_the_mouse() -> void:
	var center_screen := Vector2(get_viewport().size) / 2.0
	get_viewport().warp_mouse(center_screen)


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
