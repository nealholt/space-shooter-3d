extends CharacterBody3D
class_name FighterNPC

signal destroyed

var aim_assist:AimAssist
var controller : CharacterBodyControlParent
# The following is used for some testing, to display
# out the npc's health
var health_component:HealthComponent
var missile_lock:MissileLockGroup

# TODO left off here merging player.gd and npc_fighter code
# NPC fighter needs a 
#var weapon_handler:WeaponHandler

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
		if child is CharacterBodyControlParent:
			controller = child
		if child is HealthComponent:
			health_component = child
		if child is MissileLockGroup:
			missile_lock = child


func _physics_process(delta):
	if controller:
		# Move and turn
		controller.move_and_turn(self, delta)
		# Select target
		controller.select_target(self)
		# Handle shooting of guns and missiles
		controller.shoot(self, delta)


func get_current_gun() -> Gun:
	return $Gun


func _on_health_component_health_lost() -> void:
	# Force a switch into evasion state
	controller.go_evasive()
	#print('hit on hull')
	# Trail smoke and sparks when damaged
	var percent_health = $HealthComponent.get_percent_health()
	#print(percent_health)
	if percent_health <= 0.0: #This will happen for death animation
		$DamageEmitters/MildDamage.stop_emitting()
		$DamageEmitters/MajorDamageLineSparks.stop_emitting()
		$DamageEmitters/MajorDamage.start_emitting()
	elif percent_health < 0.3:
		$DamageEmitters/MildDamage.stop_emitting()
		$DamageEmitters/MajorDamageLineSparks.start_emitting()
		$DamageEmitters/MajorDamage.stop_emitting()
	elif percent_health < 0.6:
		$DamageEmitters/MildDamage.start_emitting()
		$DamageEmitters/MajorDamageLineSparks.stop_emitting()
		$DamageEmitters/MajorDamage.stop_emitting()


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
