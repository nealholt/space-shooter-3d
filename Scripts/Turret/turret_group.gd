class_name TurretGroup extends Node

# Put a turret on every child of this node!
func _ready() -> void:
	var p:Ship = get_parent()
	for child in get_children():
		if child is TurretData:
			Turret.new_turret(child, p)


# Disable turret movement while testing
func disable_for_testing() -> void:
	for child in get_children():
		if child is TurretData:
			var t:Turret = child.get_child(0)
			t.turret_motion.queue_free()
			t.turret_motion = null
