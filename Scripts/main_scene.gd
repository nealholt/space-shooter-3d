extends Node
class_name MainScene

# This was all based on this tutorial:
# https://www.youtube.com/watch?v=a0UQ-t-vuzY

@onready var hud: Control = $HUD
@onready var menu: Control = $Menu
@onready var main_3d: Node3D = $Main3D
# Currently loaded level
var level_instance: Node


func _ready() -> void:
	# Make this scene globally accessible
	Global.main_scene = self


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Display player velocity
	if Global.player and is_instance_valid(Global.player):
		$HUD/Demo.text = "Velocity: %.0f" % Global.player.velocity.length()
		$HUD/Demo.text += "\nHealth: %.d" % Global.player.health_component.health
	# Exit on escape key and controller left menu button
	if Input.is_action_just_pressed('exit'):
		get_tree().quit()
	# Reset to main menu on enter key and controller start button
	if Input.is_action_just_pressed('reset'):
		to_main_menu()


func to_main_menu() -> void:
	if Global.player and is_instance_valid(Global.player):
		Global.player.set_physics_process(false)
	menu.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func unload_level() -> void:
	if(is_instance_valid(level_instance)):
		level_instance.queue_free()
	level_instance = null



func load_level(level_name:String) -> void:
	unload_level()
	var level_path := "res://Levels/%s.tscn" % level_name
	var level_resource := load(level_path)
	if(level_resource):
		level_instance = level_resource.instantiate()
		main_3d.add_child(level_instance)
		menu.visible = false
		hud.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _on_load_1_pressed() -> void:
	load_level("Level01/level1")

func _on_load_2_pressed() -> void:
	load_level("Level02/level2")

func _on_load_3_pressed() -> void:
	load_level("Level03/level3")

func _on_load_4_pressed() -> void:
	load_level("Level04/level04")

func _on_load_5_pressed() -> void:
	load_level("Level05/level_05")
