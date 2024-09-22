extends Node
class_name Controller

@export var is_laser_guided:bool = false
var target:Node3D
var data:ShootData


func set_data(shoot_data:ShootData) -> void:
	data = shoot_data
	if is_instance_valid(data.target):
		target = data.target


func move_me(body:Node3D, _delta:float) -> void:
	# Check if there is a target or guidance laser,
	# if not, do nothing.
	if !is_instance_valid(target) and !is_laser_guided:
		return
	# Seek target using look_at and constant speed.
	# Change direction on a dime. No vector addition
	# or physics.
	var target_pos := get_target_pos(body)
	body.look_at(target_pos, Vector3.UP)
	body.velocity = -body.transform.basis.z * body.speed


# Returns target position, laser guided position,
# or, if able, target intercept based on target velocity.
func get_target_pos(body:Node3D) -> Vector3:
	if is_laser_guided:
		if data.ray.is_colliding():
			return data.ray.get_collision_point()
		else: # If there is not colliding object
			# return the endpoint of the ray
			return data.ray.global_position+data.ray.global_transform.basis.z * data.ray.target_position.z
			#global_position+ray.global_transform.basis.z * ray.target_position.z
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
