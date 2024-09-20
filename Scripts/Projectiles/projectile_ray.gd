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
		# Stick on a decal before damaging and dying
		stick_decal(ray.get_collision_point(), ray.get_collision_normal())
		damage_and_die(ray.get_collider())
	# Move forward
	super._physics_process(delta)
