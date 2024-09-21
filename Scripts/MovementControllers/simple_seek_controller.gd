extends Node
class_name Controller

var target:Node3D


func set_target(t:Node3D) -> void:
	target = t


func move_me(body:Node3D, _delta:float) -> void:
	# Check if there is a target, if not, do nothing
	if !is_instance_valid(target):
		return
	# Seek target using look_at and constant speed.
	# Change direction on a dime. No vector addition
	# or physics.
	print('targeting ', Time.get_ticks_msec())
	var target_pos := get_target_pos(body)
	body.look_at(target_pos, Vector3.UP)
	body.velocity = -body.transform.basis.z * body.speed


# Returns target position or, if able, intercept
func get_target_pos(body:Node3D) -> Vector3:
	# Calculate and return target intercept
	# Make sure target has a velocity attribute, otherwise
	# use zero velocity.
	var targ_vel = Vector3.ZERO
	if "velocity" in target:
		targ_vel = target.velocity
	# Lead the target by getting the position where we
	# can intercept it from the current position at speed.
	return Global.get_intercept(
			body.global_position,
			body.speed,
			target.global_position,
			targ_vel)
