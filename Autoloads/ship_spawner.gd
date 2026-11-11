extends Node

enum SHIP_TYPE {FIGHTER, CORVETTE, CAPSHIP_FRIGATE}

# According to this: https://forum.godotengine.org/t/parse-error-referenced-non-existent-resource/95356/5
# "you shouldn’t use preload in autoload script because there will
# be a 'race' of loading files and your program will try to load
# non referenced file or things like that."
# The error is this "Parse Error: referenced non-existent resource"
# and it can be caused by circular references.
var FIGHTER_SCENE:PackedScene = load("res://Ships/fighter.tscn")
var CORVETTE_SCENE:PackedScene = load("res://Ships/corvette.tscn")
var CAPSHIP_FRIGATE_SCENE:PackedScene = load("res://Ships/capital_ship_frigate.tscn")
var NPC_CONTROLLER_SCENE:PackedScene = load("res://Controllers/npc_controller.tscn")


func new_npc_fighter(typ:SHIP_TYPE, team:String, pos:Vector3, direction:Vector3,
add_shield:bool) -> Ship:
	# Create a new fighter
	var f:Ship
	# Different sized ships have different shield sizes
	var shield_scale:float = 100.0
	
	match typ:
		SHIP_TYPE.FIGHTER:
			f = FIGHTER_SCENE.instantiate()
			shield_scale = 20.0
		SHIP_TYPE.CORVETTE:
			f = CORVETTE_SCENE.instantiate()
			shield_scale = 30.0
		SHIP_TYPE.CAPSHIP_FRIGATE:
			f = CAPSHIP_FRIGATE_SCENE.instantiate()
			shield_scale = 150.0 # TODO TESTING ???
		_: # Default / Otherwise
			push_error('Unrecognized ship type ',typ)
	
	# Attach an NPC controller
	var controller :CharacterBodyControlParent = NPC_CONTROLLER_SCENE.instantiate()
	f.add_child(controller)
	f.controller = controller
	# Attach a shield
	if add_shield:
		Shield.new_shield(f, shield_scale)
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
