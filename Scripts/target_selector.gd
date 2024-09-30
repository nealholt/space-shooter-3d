extends Node
class_name TargetSelector

var my_group:String
# Group from which targets will be selected
var target_group:String
# Who is doing the targeting. Targeter targets the target
var targeter: Node3D
# current target
var target:Node3D


func setup(npc:Node3D, team_affiliation:String) -> void:
	targeter = npc
	my_group = team_affiliation
	if my_group == "red_team":
		target_group = "blue team"
	else:
		target_group = "red team"



func update_target() -> void:
	# Keep it simple for now
	# Set target to be centermost in view from group
	target = Global.get_center_most_from_group(target_group,targeter)


func get_target() -> Node3D:
	# If the target died or whatever, get a new one
	if !is_instance_valid(target):
		update_target()
	return target
