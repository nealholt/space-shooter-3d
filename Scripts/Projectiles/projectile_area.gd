extends Projectile
class_name ProjectileArea


# Override parent class
func set_data(dat:ShootData) -> void:
	super.set_data(dat)
	# Check if this is a bullet that should not make a
	# whiffing noise. Currently only player bullets
	# should not self-whiff
	$Area3D.set_collision_mask_value(3, dat.use_near_miss)


func _on_area_3d_area_entered(area: Area3D) -> void:
	# If we hit a near-miss detector
	if area.is_in_group("near-miss detector"):
		start_near_miss_audio()
		return
	elif data.collision_exception1 and data.collision_exception1 == area:
		return
	elif data.collision_exception2 and data.collision_exception2 == area:
		return
	else:
		damage_and_die(area)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if data.collision_exception1 and data.collision_exception1 == body:
		return
	elif data.collision_exception2 and data.collision_exception2 == body:
		return
	else:
		damage_and_die(body)
