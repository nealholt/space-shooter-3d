extends Node3D

# Source
# https://www.udemy.com/course/complete-godot-3d/learn/lecture/41204698#questions

var index = -1

var current_weapon: Node3D

func _ready() -> void:
	change_weapon()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_weapons"):
		change_weapon()


func equip(active_weapon:Node3D) -> void:
	# Pre: All children must be weapons
	current_weapon = active_weapon
	for child in get_children():
		if child == active_weapon:
			# Precondition: child is a Gun
			child.activate()
		else:
			# Precondition: child is a Gun
			child.deactivate()


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
