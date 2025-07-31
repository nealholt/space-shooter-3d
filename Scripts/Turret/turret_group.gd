class_name TurretGroup extends Node

# Put a turret on every child of this node!
func _ready() -> void:
	for child in get_children():
		if child is TurretData:
			Turret.new_turret(child)
