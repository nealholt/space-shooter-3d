extends Node
class_name MainScene

# This was all based on this tutorial:
# https://www.youtube.com/watch?v=a0UQ-t-vuzY

@onready var hud: Control = $HUD
@onready var menu: Control = $Menu
@onready var main_3d: Node3D = $Main3D
# Currently loaded level
var level_instance: Node
var fullscreen:=true


func _ready() -> void:
	# Start with load level 1 button focused. This lets you
	# use arrow keys and enter to nabigate the menus.
	# After completing a level, you might want to default
	# the next level to be in focus.
	$Menu/HBoxContainer/SceneOptions/Load1Balloons.grab_focus()
	# Set display to fullscreen. When I tried to set
	# fullscreen as the default in project settings,
	# the toggle button was broken, but this way it works.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	# Make this scene globally accessible
	Global.main_scene = self
	Global.input_man = $InputManager
	# Make sure the interface is synced with the default
	# input manager settings.
	_on_toggle_inverted_toggled(Global.input_man.use_inverted)
	_on_toggle_controls_toggled(Global.input_man.use_mouse_and_keyboard)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Display player velocity
	if Global.player and is_instance_valid(Global.player):
		$HUD/Demo.text = "Velocity: %.0f" % Global.player.velocity.length()
		$HUD/Demo.text += "\nHealth: %.d" % Global.player.health_component.health
		$HUD/Demo.text += "\nFPS: %d" % Engine.get_frames_per_second()



func _input(_event: InputEvent) -> void:
	# Exit to main menu on exit, or if we're already
	# on the main menu, exit game
	if Input.is_action_just_released('exit'):
		if menu.visible:
			print('quitting')
			get_tree().quit()
		else:
			print('to main menu')
			to_main_menu()
	# "p" to pause the game, but not from the main menu
	elif Input.is_action_just_pressed('pause') and !menu.visible:
		$PauseCanvasLayer.visible = true
		get_tree().paused = true



func to_main_menu() -> void:
	unload_level()
	menu.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Reset focus to load level 1 button. This lets you
	# use arrow keys and enter to nabigate the menus.
	# After completing a level, you might want to default
	# the next level to be in focus.
	$Menu/HBoxContainer/SceneOptions/Load1Balloons.grab_focus()


func set_hud_label(text:String) -> void:
	$HUD/Demo.text = text


func unload_level() -> void:
	if(is_instance_valid(level_instance)):
		level_instance.queue_free()
	level_instance = null
	# Queue free every child of main_3d
	for c in main_3d.get_children():
		c.queue_free()


func load_level(level_name:String) -> void:
	unload_level()
	var level_path := "res://Levels/%s.tscn" % level_name
	var level_resource := load(level_path)
	if(level_resource):
		level_instance = level_resource.instantiate()
		main_3d.add_child(level_instance)
		menu.visible = false
		hud.visible = true
		Global.input_man.refresh()
	# Set team node references in the global script
	Global.red_team_group = null
	Global.blue_team_group = null
	for c in Global.get_all_children(main_3d):
		if c is TeamSetup:
			if c.team == "red team":
				Global.red_team_group = c
			elif c.team == "blue team":
				Global.blue_team_group = c
			else:
				printerr('Unrecognized team %s in main_scene.gd load_level' % c.team)


func _on_load_1_pressed() -> void:
	load_level("Level01Balloons/level1")

func _on_load_2_pressed() -> void:
	load_level("Level02ShootingGallery/level2")

func _on_load_3_pressed() -> void:
	load_level("Level03OneVsFive/level3")

func _on_load_4_pressed() -> void:
	load_level("Level04NPCTargeting/level04")

func _on_load_5_pressed() -> void:
	load_level("Level05Furball/level_05")

func _on_load_6_pressed() -> void:
	load_level("Level06TurretTest/TurretTesting")

func _on_load_7_pressed() -> void:
	load_level("Level07CapitalShipTest/capital_ship_test")

func _on_load_8_near_miss_sound_pressed() -> void:
	load_level("Level08NearMiss/near_miss_testing")

func _on_load_9_shield_pressed() -> void:
	load_level("Level09ShieldTest/shield_experiments")

func _on_load_10_asteroids_pressed() -> void:
	load_level("Level10Asteroids/AsteroidField")

func _on_load_11_damage_effects_pressed() -> void:
	load_level("Level11DamageEffectTest/damage_effects_scene")

func _on_load_12_collision_experiment_pressed() -> void:
	load_level("Level12CollisionTest/collision_experiments")

func _on_load_13_space_station_defense_pressed() -> void:
	load_level("Level13Everything/EverythingLevel")

func _on_load_14_delete_me_pressed() -> void:
	load_level("Level14DeleteMe/delete_me")


func _on_toggle_fullscreen_pressed() -> void:
	fullscreen = !fullscreen
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_toggle_inverted_toggled(toggled_on: bool) -> void:
	Global.input_man.toggle_inverted(toggled_on)


func _on_toggle_controls_toggled(toggled_on: bool) -> void:
	Global.input_man.toggle_mouse_and_keyboard(toggled_on)
	if toggled_on:
		$Menu/HBoxContainer/MouseKeyboardControls.visible = true
		$Menu/HBoxContainer/ControllerControls.visible = false
	else:
		$Menu/HBoxContainer/MouseKeyboardControls.visible = false
		$Menu/HBoxContainer/ControllerControls.visible = true
