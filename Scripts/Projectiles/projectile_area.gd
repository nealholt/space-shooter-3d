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
	else:
		damage_and_die(area)


func _on_area_3d_body_entered(body: Node3D) -> void:
	damage_and_die(body)
