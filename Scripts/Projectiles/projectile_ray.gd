extends Projectile
class_name ProjectileRay

@onready var ray:RayCast3D = $RayCast3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Change ray length to extend from current
	# position to new position.
	ray.target_position.z = -(velocity * delta).length()
	# Check for and handle collisions.
	if ray.is_colliding():
		damage_and_die(ray.get_collider())
	else:
		# Move forward
		super._physics_process(delta)
