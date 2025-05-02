class_name VisualEffect extends Node3D
## Parent class for all visual effects

var remote_transform:RemoteTransform3D

func play() -> void:
	pass

func play_at(loc:Vector3) -> void:
	global_position = loc

func face_and_play(loc:Vector3, to_face:Vector3) -> void:
	play_at(loc)
	# You have to set the global position BEFORE look_at!
	# play sets the global position
	look_at(to_face)

func play_at_angle(loc:Vector3, angle:Vector3) -> void:
	rotation = angle
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
