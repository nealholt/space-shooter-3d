extends Projectile
class_name ProjectileArea


func _on_area_3d_area_entered(area: Area3D) -> void:
	damage_and_die(area)


func _on_area_3d_body_entered(body: Node3D) -> void:
	damage_and_die(body)
