extends CharacterBody3D
class_name FighterNPC

signal destroyed

var aim_assist:AimAssist
var burning_trail:BurningTrail # This is a visual effect
var controller:CharacterBodyControlParent
var health_component:HealthComponent
var missile_lock:MissileLockGroup
var weapon_handler:WeaponHandler

# The deathExplosion happens when the ship
# is first killed. Then the finalExplosion
# happens after the death animation completes.
# This, like many other things, was inspired
# by House of the Dying Sun.
@export var deathExplosion : PackedScene
@export var finalExplosion : PackedScene


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
		elif child is BurningTrail:
			burning_trail = child
		elif child is CharacterBodyControlParent:
			controller = child
		elif child is HealthComponent:
			health_component = child
			# Connect signals with code
			health_component.health_lost.connect(_on_health_component_health_lost)
			health_component.died.connect(_on_health_component_died)
		elif child is MissileLockGroup:
			missile_lock = child
		elif child is WeaponHandler:
			weapon_handler = child


func _physics_process(delta):
	if controller:
		# Move and turn
		controller.move_and_turn(self, delta)
		# Select target
		controller.select_target(self)
		# Handle shooting of guns and missiles
		controller.shoot(self, delta)


func get_current_gun() -> Gun:
	return weapon_handler.current_weapon


func _on_health_component_health_lost() -> void:
	# Communicate damage to the controller.
	# This will let npcs take evasive action.
	if controller:
		controller.took_damage()
	# Trail smoke and sparks when damaged
	if health_component and burning_trail:
		burning_trail.display_damage(health_component.get_percent_health())


# TODO left off here merging player.gd and npc_fighter code
func _on_health_component_died() -> void:
	# Explode
	var explosion = deathExplosion.instantiate()
	# Add to main_3d, not root, otherwise the added
	# node might not be properly cleared when
	# transitioning to a new scene.
	Global.main_scene.main_3d.add_child(explosion)
	explosion.global_position = global_position
	# Tell controller to enter death animation state
	# which should be some sort of chaotic tumble
	controller.enter_death_animation()
	# Start a timer, if it's not already started.
	# Go into death animation for this duration.
	if $DeathTimer.is_stopped():
		$DeathTimer.start(randf_range(1.5, 4.5))


func _on_death_timer_timeout() -> void:
	destroyed.emit()
	# At the end of the timer, add an explosion to
	# main_3d and properly queue free this ship
	var explosion = finalExplosion.instantiate()
	# Add to main_3d, not root, otherwise the added
	# node might not be properly cleared when
	# transitioning to a new scene.
	Global.main_scene.main_3d.add_child(explosion)
	explosion.global_position = global_position
	# Wait until the end of the frame to execute queue_free
	Callable(queue_free).call_deferred()
