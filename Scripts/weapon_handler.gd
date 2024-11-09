extends Node3D
class_name WeaponHandler

# Source
# https://www.udemy.com/course/complete-godot-3d/learn/lecture/41204698#questions

var index = -1

var current_weapon: Gun

func _ready() -> void:
	# Initially deactivate all weapons
	deactivate_all()
	# Set index and equip first weapon
	change_weapon()


func deactivate_all() -> void:
	# Pre: All children must be weapons
	for child in get_children():
		# Precondition: child is a Gun
		child.deactivate()


func equip(active_weapon:Node3D) -> void:
	# New version doesn't re-deactivate all guns,
	# just the current gun. Old version was
	# causing issues with LaserGun.
	# A lot of the old version code was
	# copied into the deactivate_all() function.
	# New version:
	if current_weapon:
		current_weapon.deactivate()
	current_weapon = active_weapon
	current_weapon.activate()
	# Old version:
	## Pre: All children must be weapons
	#current_weapon = active_weapon
	#for child in get_children():
		#if child == active_weapon:
			## Precondition: child is a Gun
			#child.activate()
		#else:
			## Precondition: child is a Gun
			#child.deactivate()


# https://www.udemy.com/course/complete-godot-3d/learn/lecture/41204700#questions
func change_weapon() -> void:
	index = wrapi(index+1, 0, get_child_count())
	equip(get_child(index))


func shoot(shooter:Node3D, target = null) -> void:
	# Whether or not an instance is valid is
	# different from null. queue_free makes an 
	# instance invalid, but not null, hence
	# the necessity of this check.
	if !is_instance_valid(target):
		target = null
	current_weapon.shoot(shooter, target)


func is_automatic() -> bool:
	return current_weapon.automatic


func get_bullet_speed() -> float:
	return current_weapon.bullet_speed
