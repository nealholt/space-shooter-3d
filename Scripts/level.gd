class_name Level extends Node3D

var end_screen : EndScreen # aka victory_layer
var red_team : TeamSetup
var blue_team : TeamSetup

func _ready() -> void:
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

# This function is called after a ship dies.
func check_win_loss(s:Ship) -> void:
	# If there is no end screen or enemy team, return.
	# There's nothing to do here.
	if !(end_screen and red_team):
		return
	# If the player died. Show defeat.
	# If the entire red team died. Show victory.
	if Global.player == s:
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
