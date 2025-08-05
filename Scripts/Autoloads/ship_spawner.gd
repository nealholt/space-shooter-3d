extends Node

const FIGHTER_SCENE:PackedScene = preload("res://Scenes/Ships/fighter.tscn")
const NPC_CONTROLLER_SCENE:PackedScene = preload("res://Scenes/MovementControllers/npc_controller.tscn")


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
	f.look_at(pos + direction)
	return f
