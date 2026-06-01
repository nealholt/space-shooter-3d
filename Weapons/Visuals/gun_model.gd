class_name GunModel extends Node3D

@export var animation_player:AnimationPlayer

# The gun script should call this.
# All gun models with animations will need to name the animation
# "gun_animation"
func shoot() -> void:
	if animation_player:
		animation_player.play('gun_animation')

func stop_animating() -> void:
	if animation_player:
		animation_player.stop()
