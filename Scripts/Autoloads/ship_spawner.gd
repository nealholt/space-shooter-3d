extends Node

const FIGHTER_SCENE:PackedScene = preload("res://Scenes/Ships/fighter.tscn")

static func new_npc_fighter(my_parent:TeamSetup, pos:Vector3, direction:Vector3) -> Ship:
	# Create a new fighter
	var f := FIGHTER_SCENE.instantiate()
	# Attach an NPC controller
	var controller := NPCStateMachine.new()
	f.add_child(controller)
	# Attach new fighter to a particular team node
	my_parent.add_child(f)
	# Position and orient the fighter
	f.global_position = pos
	f.look_at(pos + direction)
	# Set team properties
	my_parent.set_team_properties(f)
	return f
