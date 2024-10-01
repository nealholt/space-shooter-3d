extends Node
class_name TargetSelector

var my_group:String
# Group from which targets will be selected
var target_group:String
# current target
var target:Node3D


func update_target(targeter:Node3D) -> void:
	# Keep it simple for now
	# Set target to be centermost in view from group
	target = Global.get_center_most_from_group(target_group,targeter)


func get_target(targeter:Node3D) -> Node3D:
	# If the target died or whatever, get a new one
	if !is_instance_valid(target):
		update_target(targeter)
	return target
