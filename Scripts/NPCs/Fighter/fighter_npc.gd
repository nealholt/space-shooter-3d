extends CharacterBody3D
class_name FighterNPC

signal destroyed

@export var deathExplosion : PackedScene

@export var controller : CharacterBodyControlParent


func _physics_process(delta):
	controller.move_and_turn(self, delta)
	if controller.firing:
		$Gun.shoot(self)


func get_current_gun() -> Gun:
	return $Gun


func _on_health_component_health_lost() -> void:
	# Force a switch into evasion state
	controller.go_evasive()
	#print('hit on hull')
	# Trail smoke and sparks when damaged
	var percent_health = $HealthComponent.get_percent_health()
	#print(percent_health)
	if percent_health < 0.25:
		$DamageEmitters/MildDamage.stop_emitting()
		$DamageEmitters/MajorDamageLineSparks.stop_emitting()
		$DamageEmitters/MajorDamage.start_emitting()
	elif percent_health < 0.5:
		$DamageEmitters/MildDamage.stop_emitting()
		$DamageEmitters/MajorDamageLineSparks.start_emitting()
		$DamageEmitters/MajorDamage.stop_emitting()
	elif percent_health < 0.8:
		$DamageEmitters/MildDamage.start_emitting()
		$DamageEmitters/MajorDamageLineSparks.stop_emitting()
		$DamageEmitters/MajorDamage.stop_emitting()


func _on_health_component_died() -> void:
	destroyed.emit()
	# Explode
	var explosion = deathExplosion.instantiate()
	# Add to main_3d, not root, otherwise the added
	# node might not be properly cleared when
	# transitioning to a new scene.
	Global.main_scene.main_3d.add_child(explosion)
	explosion.global_position = global_position
	# Wait until the end of the frame to execute queue_free
	Callable(queue_free).call_deferred()
