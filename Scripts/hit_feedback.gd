extends Node

func hit() -> void:
	$HitAudio.play()
	$AnimationPlayer.play('TakeDamage')
