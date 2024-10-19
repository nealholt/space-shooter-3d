extends CharacterBody3D
class_name FighterNPC

signal destroyed

@export var deathExplosion : PackedScene
@export var finalExplosion : PackedScene

@export var controller : CharacterBodyControlParent

# The following is used for some testing, to display
# out the npc's health
@export var health_component:HealthComponent

@export var missile_lock:MissileLockGroup

@export var aim_assist:AimAssist


func _physics_process(delta):
	controller.move_and_turn(self, delta)
	if controller.firing:
		$Gun.shoot(self)
	if missile_lock:
		missile_lock.update(self, delta)

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
	# Start a timer. Go into death animation
	# for this duration.
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
