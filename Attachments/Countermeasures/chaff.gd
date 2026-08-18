class_name Chaff extends Countermeasure

@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var timer: Timer = $Timer

# Chaff emitting ship is untargetable for duration.
@export var duration:float = 4.0 ## seconds

func _ready() -> void:
	particles.lifetime = duration
	timer.wait_time = duration
	# Allow others to target us when chaff is finished.
	# You might think the particles.finished signal would
	# suffice, but that signal doesn't trigger until
	# every last particle has faded out, which is longer
	# than "lifetime" which is how long the emitter is
	# emitting new particles. Thus we use a parallel
	# timer instead.
	timer.timeout.connect(target_block_deactivated.emit)

# Emit a particle effect just to give feedback that the
# countermeasure activated.
func activate_countermeasure(_data:ShootData) -> void:
	#print_targeter_summary() # Testing
	# Can't reactivate until previous activation concludes
	if !timer.is_stopped(): return
	# Otherwise activate chaff
	timer.start()
	particles.emitting = true
	target_block_activated.emit()
	remove_invalid_targeters()
	# Tell all projectiles targeting us to lose targeting.
	for targeter:Node3D in targeters:
		if targeter is Projectile:
			var p:Projectile = (targeter as Projectile)
			p.data.target = null
		elif targeter is Ship:
			var s:Ship = (targeter as Ship)
			s.reset_target()
