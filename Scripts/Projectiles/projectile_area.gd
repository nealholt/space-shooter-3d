extends Projectile
class_name ProjectileArea


# Override parent class
func set_data(dat:ShootData) -> void:
	super.set_data(dat)
	# Check if this is a bullet that should not make a
	# whiffing noise. Currently only player bullets
	# should not self-whiff
	if dat.turn_off_near_miss:
		$Area3D.set_collision_layer_value(3, false)

func _on_area_3d_area_entered(area: Area3D) -> void:
	damage_and_die(area)


func _on_area_3d_body_entered(body: Node3D) -> void:
	damage_and_die(body)
