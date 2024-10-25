extends Node
class_name AimAssist

# The idea is that this node will identify whether
# a ship (or turret) has aim assist, and will
# play a tone when the ship does if an audio
# player is attached.

# Aim assist will still need to be communicated
# to the firing gun and will cause projectiles
# to be adjusted to face an intercept point
# rather than where ever they were aimed.
# The ship or turret should call use_aim_assist
# and pass the result to the firing gun.

# Aim assist is live is shooter is within
# angle_assist_limit degrees of pointing
# at target intercept.
@export var angle_assist_limit:float = 3.0 # degrees
var angle_assist_limit_radians:float

# Audio to play when aim assist is live
var audio:AudioStreamPlayer

func _ready() -> void:
	angle_assist_limit_radians = deg_to_rad(angle_assist_limit)
	for c in get_children():
		if c is AudioStreamPlayer:
			audio = c

func use_aim_assist(shooter:Node3D, target:Node3D,
					bullet_speed:float) -> bool:
	var intercept:Vector3 = Global.get_intercept(
		shooter.global_position, bullet_speed, target)
	var angle_to = Global.get_angle_to_target(
		shooter.global_position, intercept,
		-shooter.global_basis.z)
	var do_use_aim_assist:bool = angle_to < angle_assist_limit_radians
	play_audio(do_use_aim_assist)
	return do_use_aim_assist

func play_audio(do_use_aim_assist:bool) -> void:
	if audio:
		if do_use_aim_assist and !audio.playing:
			audio.play()
		if !do_use_aim_assist and audio.playing:
			audio.stop()
