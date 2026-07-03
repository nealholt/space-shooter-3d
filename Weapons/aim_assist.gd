class_name AimAssist extends Node

const AIMASSIST_SCENE:PackedScene = preload("res://Weapons/aim_assist.tscn")

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

# Aim assist is active if shooter is within
# angle_assist_limit of pointing at target intercept.
@export_range(0, 90, 0.1, "radians_as_degrees") var angle_assist_limit: float = deg_to_rad(3.0)

# Audio to play when aim assist is active
var audio:AudioStreamPlayer


static func new_aim_assist(my_parent:Node3D, angle_assist_lim:float) -> AimAssist:
	var t := AIMASSIST_SCENE.instantiate()
	my_parent.add_child(t)
	t.set_assist_limit(angle_assist_lim)
	return t


func _ready() -> void:
	for c in get_children():
		if c is AudioStreamPlayer:
			audio = c
		else:
			push_error('Unexpected child of aim assist: ', c)


func set_assist_limit(angle_assist_lim:float) -> void:
	angle_assist_limit = angle_assist_lim


func use_aim_assist(sd:ShootData) -> bool:
	var shooter:Node3D = sd.shooter
	var target:Node3D = sd.target
	var bullet_speed:float = sd.bullet_speed
	var intercept:Vector3 = Global.get_intercept(
		shooter.global_position, bullet_speed, target)
	# If shooter is the player and mouse controls are in use
	# then this needs to be handled differently;
	# do_use_aim_assist is true if angle from where mouse / camera
	# is looking is within limit, not from where shooter is looking.
	if shooter == Global.player and InputManager.im.use_mouse_and_keyboard:
		return use_aim_assist_mouse(intercept)
	# Otherwise calculate whether or not to use aim assist
	# from the shooter's perspective.
	var angle_to:float = Global.get_angle_to_target(
		shooter.global_position, intercept,
		-shooter.global_basis.z)
	var do_use_aim_assist:bool = angle_to < angle_assist_limit
	play_audio(do_use_aim_assist)
	return do_use_aim_assist

# Detmerine aim assist usage from relative positions
# of camera and mouse.
# If angle between two vectors (camera to intercept versus
# camera to mouse) is less than angle_assist_limit
# then return true for do_use_aim_assist
func use_aim_assist_mouse(intercept:Vector3) -> bool:
	# Use the first person camera! If you use any other
	# camera, then you'll be able to shoot from a weird angle.
	# HOWEVER if you use the "look" feature (hold control)
	# you will rotate the first person camera to face the
	# target and you'll still be able to shoot at it while
	# flying a different direction. This is honestly so
	# cool that I don't want to fix it yet. The fix would
	# be to make sure "looking" takes place from the
	# shooter (ship or gun) perspective, not the camera
	# perspective.
	var camera := CameraGroup.cg.get_look_camera()
	var vect_to_cursor := camera.project_ray_normal(InputManager.im.mouse_pos)
	var vect_to_intercept := intercept - camera.global_position
	var angle_to:float = vect_to_cursor.angle_to(vect_to_intercept)
	var do_use_aim_assist:bool = angle_to < angle_assist_limit
	play_audio(do_use_aim_assist)
	return do_use_aim_assist

func play_audio(do_use_aim_assist:bool) -> void:
	if !audio:
		return
	# Only play the noise in first or third person camera
	if !is_instance_valid(CameraGroup.cg) or !CameraGroup.cg.is_first_or_third():
		return
	if do_use_aim_assist and !audio.playing:
		audio.play()
	if !do_use_aim_assist and audio.playing:
		audio.stop()
