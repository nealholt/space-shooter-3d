class_name Level extends Node3D

var end_screen : EndScreen # aka victory_layer
var red_team : TeamSetup
var blue_team : TeamSetup
var damage_tracker : DamageTracker

# Since timers count down until a stopping point, I figured
# it made sense to simply track level time so far in a float
# and increase it in _process
# The code for elapsed_time is duplicated in the Platformer3D project
var elapsed_time :float = 0.0


func _ready() -> void:
	# Connect to signal that a ship died
	EventsBus.ship_died.connect(check_win_loss)
	# Add a damage tracker
	damage_tracker = DamageTracker.new_damage_tracker(self)
	# Search for an asteroid field child. If found,
	# generate the asteroid field.
	# This is done instead of using the _ready function
	# in asteroid_field.gd because the player needs
	# to be instantiated before the asteroid field.
	for c:Node in get_children():
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
	# Create an environment tweener, attach it as a child,
	# and tell it to copy baseline environment values
	var envt :EnvironmentTweener = EnvironmentTweener.new_environment_tweener(self)
	envt.backup_environment_baselines.call_deferred($WorldEnvironment.environment)


# Update elapsed level time
func _process(delta: float) -> void:
	elapsed_time += delta


func get_elapsed_time() -> String:
	var minutes:int = int(elapsed_time/60)
	# Pad minutes with a zero
	var opt_zero_min: String = '0' if minutes < 10 else ''
	var seconds:int = int(elapsed_time)%60
	# Pad seconds with a zero
	var opt_zero_sec: String = '0' if seconds < 10 else ''
	return opt_zero_min+str(minutes)+':'+opt_zero_sec+str(seconds)


# This function is called when something dies.
# "something" includes ships and orbs only (if I recall
# correctly)
func check_win_loss(dead_thing:Ship) -> void:
	# If there is no end screen, return.
	# There's nothing to do here.
	if !end_screen: return
	# Update elapsed time
	end_screen.time_label.text = 'Elapsed Time '+get_elapsed_time()
	# If the player died. Show defeat.
	# If the entire red team died. Show victory.
	if Ship.player == dead_thing:
		end_screen.defeat()
		# Prevent reactivation of end_screen.
		EventsBus.ship_died.disconnect(check_win_loss)
	# Verify that there is a red team
	elif !is_instance_valid(red_team):
		return
	# This assumes the red team is always the enemy.
	elif red_team.get_child_count() == 0:
		end_screen.victory([false, false, false])
		# Prevent reactivation of end_screen.
		EventsBus.ship_died.disconnect(check_win_loss)
	# Unfortunately since the signal is emitted from the
	# ship that died, the red_team won't actually have
	# no children yet, so we also check if there is one
	# dead child.
	elif red_team.get_child_count() == 1:
		var child:HealthComponent = red_team.get_child(0).health_component
		if child.is_dead():
			end_screen.victory([false, false, false])
			# Prevent reactivation of end_screen.
			EventsBus.ship_died.disconnect(check_win_loss)


func center_the_mouse() -> void:
	var center_screen :Vector2 = Vector2(get_viewport().size) / 2.0
	get_viewport().warp_mouse(center_screen)


func print_damage_data() -> void:
	damage_tracker.display_data()


# This should be overridden
func get_level_description() -> String:
	return 'This should be overridden'
