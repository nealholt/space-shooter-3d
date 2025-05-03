class_name VisualEffect extends Node3D
## Parent class for all visual effects

var remote_transform:RemoteTransform3D

func play() -> void:
	pass

func play_at(loc:Vector3) -> void:
	global_position = loc
	play()

# The following was initially used for applying bullet decals.
# That might still be the only thing it's used for.
func play_at_angle(loc:Vector3, angle:Vector3) -> void:
	global_position = loc
	# https://forum.godotengine.org/t/up-vector-and-direction-between-node-origin-and-target-are-aligned-look-at-failed/20575/2
	# .is_equal_approx() should be used to compare vectors
	# because of this issue:
	# https://forum.godotengine.org/t/comparing-vectors-return-false-even-theyre-same/22474/2
	# however, the solution given on that webpage
	# is not ideal.
	if angle.is_equal_approx(Vector3.DOWN):
		rotation_degrees.x = 90
	elif angle.is_equal_approx(Vector3.UP):
		rotation_degrees.x = -90
	elif !angle.is_equal_approx(Vector3.ZERO):
		look_at(global_position - angle, Vector3(0,1,0))
	play()


func face_and_play(loc:Vector3, to_face:Vector3) -> void:
	global_position = loc
	# You have to set the global position BEFORE look_at!
	# play sets the global position
	look_at(to_face)
	play()

func play_with_transform(loc:Vector3, tf:Transform3D) -> void:
	transform = tf
	play_at(loc)

func play_remote_transform(remote_mover:Node3D) -> void:
	# Create a new remote transform, attach it
	# to the thing the effect should move with,
	# then set the transform's path to self
	remote_transform = RemoteTransform3D.new()
	remote_mover.add_child(remote_transform)
	remote_transform.remote_path = get_path()
	# Play the effect
	play()

func is_playing() -> bool:
	return false

func stop() -> void:
	_on_animation_finished()

func _on_animation_finished() -> void:
	# Free any remote transform
	if is_instance_valid(remote_transform):
		remote_transform.queue_free()
