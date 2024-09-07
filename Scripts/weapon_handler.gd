extends Node3D

# Source
# https://www.udemy.com/course/complete-godot-3d/learn/lecture/41204698#questions

@export var weapon1: Node3D
@export var weapon2: Node3D

var current_weapon: Node3D

func _ready() -> void:
	equip(weapon1)

func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("weapon1"):
		#equip(weapon1)
	#elif event.is_action_pressed("weapon2"):
		#equip(weapon2)
	#if event.is_action_pressed("next_weapon"):
	if event.is_action_pressed("left_trigger"):
		change_weapon(1)
	#elif event.is_action_pressed("previous_weapon"):
		#change_weapon(-1)

func equip(active_weapon:Node3D) -> void:
	# Pre: All children must be weapons
	current_weapon = active_weapon
	for child in get_children():
		if child == active_weapon:
			child.visible = true
			child.set_process(true)
		else:
			child.visible = false
			child.set_process(false)

# https://www.udemy.com/course/complete-godot-3d/learn/lecture/41204700#questions
func change_weapon(i:int) -> void:
	var index:int = get_current_index()
	index = wrapi(index+i, 0, get_child_count())
	equip(get_child(index))

func get_current_index() -> int:
	for index in get_child_count():
		if get_child(index).visible:
			return index
	return -1 # This should never happen

func shoot(shoot_data:ShootData) -> void:
	current_weapon.shoot(shoot_data)
