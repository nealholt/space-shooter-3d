extends Node

# This was all based on this tutorial:
# https://www.youtube.com/watch?v=a0UQ-t-vuzY
# This is a location for anything we want to be globally accessible.

var main_scene: MainScene
var player: CharacterBody3D
# For now I'm globally turning off the hud when in
# camera views other than first person.
var targeting_hud_on:bool = true

# Until I find a better home for these functions, I'm putting them here
# Control-Shift-f to search for anywhere text is found


# Get the member of the given group who is nearest to
# the center of the looker's view.
# This is initially used by seeking missiles and
# NPCs.
func get_center_most_from_group(group:String,looker):
	# Identify target with smallest angle to
	var targets = get_tree().get_nodes_in_group(group)
	var most_centered # This is a target-type variable
	var smallest_angle_to := 7.0 # Start off with anything over 2pi
	var temp_angle_to : float
	for target in targets:
		temp_angle_to = Global.get_angle_to_target(looker.global_position, target.global_position, -looker.global_transform.basis.z)
		if temp_angle_to < smallest_angle_to:
			smallest_angle_to = temp_angle_to
			most_centered = target
	return most_centered


# I'm pretty sure this is just used in Player and FighterNPC
func get_angle_to_target(seeker_pos:Vector3, target_pos:Vector3, facing_dir:Vector3) -> float:
	# Pre: target_pos is a Vector3 representing x,y,z
	# coordinates in space.
	# seeker_pos is a Vector3 representing x,y,z
	# coordinates in space.
	# facing_dir is a Vector3 representing the direction
	# we want to find the angle with respect to.
	# Post: Uses Law of Cosines to calculate and
	# return the difference between heading angle
	# (facing_dir) and global angle to target
	# (dir_to) in radians.
	# Typically, facing_dir will be -seeker.global_transform.basis.z
	# but it can be useful to ask about 
	# seeker.global_transform.basis.y to see if target
	# is above or below, or use seeker.global_transform.basis.x
	# to see if target is to the left or right.
	# Return value guaranteed to be between 0 and pi
	var dir_to = seeker_pos.direction_to(target_pos)
	# Normalizing does not seem to be necessary at
	# all, but I'll leave this here in case
	#facing_dir = facing_dir.normalized()
	#dir_to = dir_to.normalized()
	return acos(facing_dir.dot(dir_to))


# This is just a helper function to organize interpolated
# turning toward target.
# I'm pretty sure this is just used in Missile and Enemy
# If delta is zero then no change will be made.
# If delta is one then seeker will snap to face target.
# If delta is 0.5 the seeker will cover half the angle
# to the target. You've got to be careful with how you
# use this otherwise you'll end up with a Xeno's
# paradox of forever covering half the distance and
# never reaching the target.
# To learn more, see 9 min into this video:
# https://www.udemy.com/course/complete-godot-3d/learn/lecture/40979546
func interp_face_target(seeker:Node3D, target:Vector3, delta:float) -> Transform3D:
	#https://kidscancode.org/godot_recipes/4.x/3d/rotate_interpolate/index.html
	#I use transform.basis.y as relative "up" rather than Vector3.UP
	#So the object doesn't roll over when the target crosses past high noon
	var new_transform = seeker.transform.looking_at(target,seeker.transform.basis.y)
	return seeker.transform.interpolate_with(new_transform, delta)

