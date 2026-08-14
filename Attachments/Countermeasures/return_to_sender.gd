class_name RTSComponent extends Countermeasure

@onready var particles: GPUParticles3D = $GPUParticles3D

# Send all seeking projectiles back at their shooters.
# Emit a particle effect just to give feedback that the
# countermeasure activated.
func activate_countermeasure(_data:ShootData) -> void:
	particles.emitting = true
	remove_invalid_targeters()
	# Make any projectiles target their own shooter's hitbox
	for targeter:Node3D in targeters:
		if targeter is Projectile:
			var shooter:Node3D = targeter.data.shooter
			if 'hit_box_component' in shooter:
				targeter.set_target(shooter.hit_box_component)
				# Wipe out collision exceptions because the
				# shooter's hitbox is almost certainly one of
				# the exceptions
				targeter.data.collision_exceptions.clear()
