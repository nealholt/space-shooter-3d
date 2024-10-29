extends Projectile
class_name ProjectileArea


func _on_area_3d_area_entered(area: Area3D) -> void:
	if passes_through(area):
		pass
	# If we hit a near-miss detector
	elif area.is_in_group("near-miss detector"):
		start_near_miss_audio()
	else:
		# Global position is where to show
		# sparks or other particle effects
		damage_and_die(area, global_position)


func _on_area_3d_body_entered(body: Node3D) -> void:
	# Global position is where to show
	# sparks or other particle effects
	damage_and_die(body, global_position)
