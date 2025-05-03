extends Projectile
class_name ShotgunPellet

# This is currently exclusively used with the
# laser shotgun.

# I thought I'd go ahead and animate the shotgun
# with a bunch of pellets that zip from the
# shooter to the collision point.

var target_position : Vector3
var collision_normal:Vector3 # For orienting decal
var damagee # Thing to deal damage to.
# I'm moving damage dealing from laser_shotgun
# into here so that damage is dealt on pseudo
# impact rather than instantaneously

func set_up(start:Vector3, end:Vector3, collision_norm:Vector3, victim:Node3D) -> void:
	global_position = start
	target_position = end
	collision_normal = collision_norm
	damagee = victim
	look_at(target_position, Vector3.UP)
	# Reset velocity
	velocity = -global_transform.basis.z * speed
	# Calculate time out so it looks like the bullet
	# disappears at impact point
	var dist = global_position.distance_to(target_position)
	$Timer.start(dist/speed)

# Override parent class's on_timer_timeout
func _on_timer_timeout() -> void:
	# Damage target if there is one
	if damagee != null:
		VfxManager.play_at_angle(bullet_hole_decal, target_position, collision_normal)
		if damagee.is_in_group("damageable"):
			damagee.damage(damage, data.shooter)
		damagee = null
	queue_free()
