extends Node
class_name HitFeedback

func hit() -> void:
	$HitAudio.play()
	$AnimationPlayer.play('TakeDamage')
