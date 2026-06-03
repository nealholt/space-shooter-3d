extends Node3D
class_name WeaponHandler

# Source
# https://www.udemy.com/course/complete-godot-3d/learn/lecture/41204698#questions

var index = -1

var current_weapon: Gun


func reset_weapon_handler() -> void:
	index = -1
	# Initially deactivate all weapons
	deactivate_all()
	# Set index and equip first weapon
	change_weapon()


# This is called on NPC ships' weapon handlers so
# that targeting reticles can be removed.
func remove_texture_rects() -> void:
	for weapon in get_children():
		for gun_child in weapon.get_children():
			if gun_child is TextureRect:
				gun_child.queue_free()


func deactivate_all() -> void:
	# Pre: All children must be weapons
	for child in get_children():
		# Precondition: child is a Gun
		child.deactivate()


func equip(active_weapon:Node3D) -> void:
	if current_weapon:
		current_weapon.deactivate()
	current_weapon = active_weapon
	current_weapon.activate()


# https://www.udemy.com/course/complete-godot-3d/learn/lecture/41204700#questions
func change_weapon() -> void:
	index = wrapi(index+1, 0, get_child_count())
	equip(get_child(index))
