extends Node3D

# Source
# https://www.udemy.com/course/complete-godot-3d/learn/lecture/41204698#questions

@export var weapon1: Node3D
@export var weapon2: Node3D
@export var weapon3: Node3D
@export var weapon4: Node3D

var index = 0
const weapon_count = 4

var current_weapon: Node3D

func _ready() -> void:
	equip(weapon1)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_weapons"):
		change_weapon()


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
func change_weapon() -> void:
	index = wrapi(index+1, 0, weapon_count)
	equip(get_child(index))

func shoot(shoot_data:ShootData) -> void:
	current_weapon.shoot(shoot_data)
