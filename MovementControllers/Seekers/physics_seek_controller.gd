extends Controller
class_name PhysicsController


var acceleration := Vector3.ZERO
@export var steer_force: float = 50.0


# Override parent class
func set_data(shoot_data:ShootData) -> void:
	super.set_data(shoot_data)
	# 'Super powered' doubles turn rate and 10xs damage
	if shoot_data.super_powered:
		steer_force *= 2.0


# Override parent class
func move_me(body:Node3D, delta:float) -> void:
	# Check if there is a target or guidance laser,
	# if not, do nothing.
	if !is_instance_valid(target) and !is_laser_guided:
		return
	# Seek target using acceleration and vector
	# addition to make it feel "physics-y"
	
	# Acceleration should be zero unless this is a seeking missile
	acceleration = get_velocity_adjustment(body)
	# Adjust velocity based on acceleration
	body.velocity += acceleration * delta
	# Face the point in local space that is our current
	# position adjusted in the direction of the new
	# velocity
	body.look_at(body.transform.origin + body.velocity, body.global_transform.basis.y)


# Source:
# https://www.youtube.com/watch?v=pRYMy5uQSpo
# with a great deal of help from
# https://www.youtube.com/watch?v=cgVNu5-7f0w&ab_channel=IndieQuest
# to make it work in 3d
func get_velocity_adjustment(body) -> Vector3:
	var target_pos := get_target_pos(body)
	# Calculate the desired velocity, normalized and then
	# multiplied by speed.
	var desired : Vector3 = (target_pos - body.global_position).normalized() * body.speed
	# Return an adjustment to velocity based on the steer force.
	return (desired - body.velocity).normalized() * steer_force
