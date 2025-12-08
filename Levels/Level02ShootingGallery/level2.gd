extends Node

# Needed for showing victory screen when timer reaches zero
@onready var ui: Control = $UI


# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect the destroyed signal of the orb to the ui
	var orbs = get_tree().get_nodes_in_group("damageable")
	for orb in orbs:
		orb.destroyed.connect(ui._on_target_destroyed)


# https://www.udemy.com/course/complete-godot-3d/learn/lecture/40786754#questions/20944900
# Level is over when this timer reaches zero
func _on_ui_times_up() -> void:
	# Turn off the player
	Global.player.set_physics_process(false)
	# Show end of level victory screen
	ui.victory()
	# Show mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
