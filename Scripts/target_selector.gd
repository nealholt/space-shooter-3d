extends Node

# Group from which targets will be selected
var target_group:String

# Get the parent of this node. We assume this parent
# has a team variable.
@onready var parent: Node3D = $".."

# current target
var target:Node3D
var target_pos:Vector3


func update_target() -> void:
	# Keep it simple for now
	# Set target to be centermost in view from group
	target = Global.get_center_most_from_group(target_group,parent)


# Get the position to shoot at in order to lead the target
func get_lead(bullet_speed:float) -> Vector3:
	# If the target died or whatever, get a new one
	if !is_instance_valid(target):
		update_target()
	# If the target is valid, then update target info
	# otherwise return origin
	if !is_instance_valid(target):
		return Vector3.ZERO
	else:
		# Calculate position to use to lead the target.
		# This if is explicitly to allow npcs to target orbs
		# but could be important on any stationary target.
		var targ_vel = Vector3.ZERO
		#if !(target is StaticBody3D):
		if "velocity" in target:
			targ_vel = target.velocity
		target_pos = Global.get_intercept(
				parent.global_position,
				bullet_speed,
				target.global_position,
				targ_vel)
		return target_pos


# Pre: target_pos is up to date
func get_distance_to_target() -> float:
	# Distance to target
	# Use distance squared for small efficiency gain
	return parent.global_position.distance_squared_to(target_pos)

