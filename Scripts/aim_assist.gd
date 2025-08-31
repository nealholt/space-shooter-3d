class_name AimAssist extends Node

const AIMASSIST_SCENE:PackedScene = preload("res://Scenes/aim_assist.tscn")

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


static func new_aim_assist(my_parent:Node3D, angle_assist_limit_deg:float) -> AimAssist:
	var t := AIMASSIST_SCENE.instantiate()
	my_parent.add_child(t)
	t.set_assist_limit_deg(angle_assist_limit_deg)
	return t


func _ready() -> void:
	angle_assist_limit_radians = deg_to_rad(angle_assist_limit)
	for c in get_children():
		if c is AudioStreamPlayer:
			audio = c

func set_assist_limit_deg(angle_assist_limit_deg:float) -> void:
	angle_assist_limit = angle_assist_limit_deg
	angle_assist_limit_radians = deg_to_rad(angle_assist_limit)

func use_aim_assist(shooter:Node3D, target:Node3D,
					bullet_speed:float) -> bool:
	# If shooter is the player and mouse controls are in use
	# then this needs to be handled differently;
	# do_use_aim_assist is true if angle from where mouse / camera
	# is looking is within limit, not from where shooter is looking.
	if shooter == Global.player and Global.input_man.use_mouse_and_keyboard:
		return use_aim_assist_mouse(shooter, target, bullet_speed)
	# Otherwise calculate whether or not to use aim assist
	# from the shooter's perspective.
	var intercept:Vector3 = Global.get_intercept(
		shooter.global_position, bullet_speed, target)
	var angle_to:float = Global.get_angle_to_target(
		shooter.global_position, intercept,
		-shooter.global_basis.z)
	var do_use_aim_assist:bool = angle_to < angle_assist_limit_radians
	play_audio(do_use_aim_assist)
	return do_use_aim_assist

# Detmerine aim assist usage from relative positions
# of camera and mouse.
# If angle between two vectors (camera to intercept versus
# camera to mouse) is less than angle_assist_limit_radians
# then return true for do_use_aim_assist
func use_aim_assist_mouse(shooter:Node3D, target:Node3D,
					bullet_speed:float) -> bool:
	var intercept:Vector3 = Global.get_intercept(
		shooter.global_position, bullet_speed, target)
	var camera := Global.input_man.current_viewport.get_camera_3d()
	var vect_to_cursor := camera.project_ray_normal(Global.input_man.mouse_pos)
	var vect_to_intercept := intercept - camera.global_position
	var angle_to:float = vect_to_cursor.angle_to(vect_to_intercept)
	var do_use_aim_assist:bool = angle_to < angle_assist_limit_radians
	play_audio(do_use_aim_assist)
	return do_use_aim_assist

func play_audio(do_use_aim_assist:bool) -> void:
	if !audio:
		return
	if do_use_aim_assist and !audio.playing:
		audio.play()
	if !do_use_aim_assist and audio.playing:
		audio.stop()
