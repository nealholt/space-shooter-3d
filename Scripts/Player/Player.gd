extends CharacterBody3D

signal destroyed

var aim_assist:AimAssist
var controller : CharacterBodyControlParent
# The health_component is currently only used by
# the HUD in the main scene
var health_component:HealthComponent
var missile_lock: MissileLockGroup
var weapon_handler:WeaponHandler

#I really like the idea of _ready functions
# searching through and equipping components
# they find as children.
#Search subtree for components. If found,
# save a reference to them and subscribe to
# their signals.
# Inspired by luislodosm's response here:
# https://forum.godotengine.org/t/easy-way-to-get-certain-type-of-children/21496/2
# And also the part of the following example
# https://www.gdquest.com/tutorial/godot/design-patterns/entity-component-pattern/
# at this part:
# "func _find_power_source_child(parent: Node) -> PowerSource:"
# This link is not saved elsewhere. It's a good
# little read, but acknowledges at the bottom
# that it's best for simulation-type games.
func _ready() -> void:
	# Search through children for various components
	# and save a reference to them.
	for child in get_children():
		if child is AimAssist:
			aim_assist = child
		if child is CharacterBodyControlParent:
			controller = child
		if child is HealthComponent:
			health_component = child
		if child is MissileLockGroup:
			missile_lock = child
		if child is WeaponHandler:
			weapon_handler = child


func _physics_process(delta):
	if controller:
		# Move and turn
		controller.move_and_turn(self,delta)
		# Select target
		controller.select_target(self)
		# Handle shooting of guns and missiles
		controller.shoot(self, delta)


# TODO left off here merging player.gd and npc_fighter code

func _on_health_component_died() -> void:
	destroyed.emit()
	# Load main scene if player dies
	Global.main_scene.to_main_menu()
