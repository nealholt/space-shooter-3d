extends StaticBody3D


func _on_area_3d_body_entered(_body: Node3D) -> void:
	# Play a sound
	AudioManager.play(SoundEffectSetting.SOUND_EFFECT_TYPE.GAIN)
	# Turn off the particle effect
	$GPUParticles3D.emitting = false
