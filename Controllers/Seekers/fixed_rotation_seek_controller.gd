class_name FixedRotationController extends Controller
# This class is used by seeking projectiles to guide them
# to the target.
# This class modifies rotation by a constant rate per unit time

var rotation_speed: float = deg_to_rad(90.0)

# Override parent class
func set_data(shoot_data:ShootData) -> void:
	super.set_data(shoot_data)
	# 'Super powered' doubles turn rate and 10xs damage
	if shoot_data.super_powered:
		rotation_speed *= 2.0

# Override parent class
func move_me(body:Node3D, delta:float) -> void:
	# Check if there is a target or guidance laser,
	# if not, do nothing.
	if !is_instance_valid(target) and !is_laser_guided:
		return
	# Get angle to target in radians
	var angle_to:float = Global.get_angle_to_target(body.global_position, target.global_position, -body.global_transform.basis.z)
	# Get percentage of that angle we will rotate through on this time step
	var percent:float = 1.0
	if angle_to != 0.0: # Avoid divide by zero
		percent = clampf(rotation_speed * delta / angle_to, 0.0, 1.0)
	# Rotate
	body.transform = Global.interp_face_target(body, target.global_position, percent)
	
	# In 2 dimensions it would be something like this:
	#var target_angle:float = body.global_position.angle_to(get_target_pos(body))
	#body.rotation += clampf(angle_difference(body.rotation, target_angle), -rotation_speed * delta, rotation_speed * delta)
	
	# Update velocity
	body.velocity = -body.transform.basis.z * body.speed
