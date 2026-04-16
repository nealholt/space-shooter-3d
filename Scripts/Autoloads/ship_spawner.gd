extends Node

# According to this: https://forum.godotengine.org/t/parse-error-referenced-non-existent-resource/95356/5
# "you shouldn’t use preload in autoload script because there will
# be a 'race' of loading files and your program will try to load
# non referenced file or things like that."
# The error is this "Parse Error: referenced non-existent resource"
# and it can be caused by circular references.
var FIGHTER_SCENE:PackedScene = load("res://Scenes/Ships/fighter.tscn")
var NPC_CONTROLLER_SCENE:PackedScene = load("res://Scenes/MovementControllers/npc_controller.tscn")


func new_npc_fighter(team:String, pos:Vector3, direction:Vector3) -> Ship:
	# Create a new fighter
	var f := FIGHTER_SCENE.instantiate()
	# Attach an NPC controller
	var controller := NPC_CONTROLLER_SCENE.instantiate()
	f.add_child(controller)
	# Attach new fighter to a particular team node
	Global.add_to_team_group(f, team)
	# Position and orient the fighter
	f.global_position = pos
	# I added 
	# direction.rotated(Vector3.RIGHT, PI/2.0)
	# on the next line to avoid the warning:
	# "look_at target and up vectors are colinear" but I'm concerned
	# that colinearity can still occur at certain orientations.
	f.look_at(pos + direction, direction.rotated(Vector3.RIGHT, PI/2.0))
	return f
