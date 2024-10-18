extends Node

# The idea is that this node will identify whether
# a ship (or turret) has aim assist, and will
# play a tone when the ship does if an audio
# player is attached.
# Aim assist will still need to be communicated
# to the firing gun and will cause projectiles
# to be adjusted to face an intercept point
# rather than where ever they were aimed.

# Aim assist is live is shooter is within
# angle_assist_limit degrees of pointing
# at target intercept.
@export var angle_assist_limit:float = 3 # degrees

# Audio to play when aim assist is live
@export var audio: AudioStreamPlayer3D


func use_aim_assist(shooter:Node3D, target:Node3D,
					bullet_speed:float) -> bool:
	var intercept:Vector3 = Global.get_intercept(
					shooter.global_position,
					bullet_speed,
					target)
	return true
