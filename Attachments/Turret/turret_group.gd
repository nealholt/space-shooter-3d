class_name TurretGroup extends Node

# Put a turret on every child of this node!
func _ready() -> void:
	# Get a reference to the parent. It SHOULD be a ship.
	# Except that it won't be a ship in testing scenario
	# and later on we might want to put turrets out on
	# asteroids or where ever
	var p = get_parent()
	for child in get_children():
		if child is TurretData:
			# Pass along the ship reference to the new turret.
			Turret.new_turret(child, p)


# Disable turret movement while testing
func disable_for_testing() -> void:
	for child in get_children():
		if child is TurretData:
			var t:Turret = child.get_child(0)
			t.turret_motion.queue_free()
			t.turret_motion = null
