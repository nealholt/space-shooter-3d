class_name CheckPoint extends StaticBody3D

signal reached

@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var area_3d: Area3D = $Area3D
@onready var reticle: TargetReticles = $TargetReticles

func activate_checkpoint() -> void:
	particles.emitting = true
	area_3d.monitoring = true
	reticle.show()
	reticle.is_targeted = true

func deactivate_checkpoint() -> void:
	particles.emitting = false
	area_3d.monitoring = false
	reticle.hide()
	reticle.is_targeted = false

func _on_area_3d_body_entered(_body: Node3D) -> void:
	# Play a sound
	AudioManager.play(SoundEffectSetting.SOUND_EFFECT_TYPE.GAIN)
	# Turn off
	deactivate_checkpoint.call_deferred()
	# Signal
	reached.emit()
