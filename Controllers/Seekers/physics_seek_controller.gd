class_name PhysicsController extends Controller
# This class is used by seeking projectiles to guide them
# to the target.
# This has some weird behavior.
# It modifies velocity by adding a goal velocity times a
# steer force, but when the projectile needs to adjust its
# direction by 180 degrees, this additive calculation can cause
# a projectile to appear to merely slow down before eventually
# accelerating in the opposite direction, which looks weird.
# I don't know why I'd use this over fixed rotation seek.
# However, the default missile currently does use this.

var steer_force: float = 50.0


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
	var acceleration:Vector3 = get_velocity_adjustment(body)
	# Adjust velocity based on acceleration
	body.velocity += acceleration * delta * steer_force
	
	#print('Acceleration ',acceleration.length())
	#print('Velocity ',body.velocity.length())
	
	# Face the point in local space that is our current
	# position adjusted in the direction of the new
	# velocity
	body.look_at(body.global_position + body.velocity, body.global_transform.basis.y)


# Source:
# https://www.youtube.com/watch?v=pRYMy5uQSpo
# with a great deal of help from
# https://www.youtube.com/watch?v=cgVNu5-7f0w&ab_channel=IndieQuest
# to make it work in 3d
func get_velocity_adjustment(body) -> Vector3:
	var target_pos := get_target_pos(body)
	# Calculate the desired direction
	var desired : Vector3 = body.global_position.direction_to(target_pos)
	# This does the exact same thing as the above.
	#var desired : Vector3 = (target_pos - body.global_position).normalized()
	# Return an adjustment to velocity based on the steer force.
	# Normalize velocity and the difference to get consistent
	# acceleration.
	return (desired - body.velocity.normalized()).normalized()
