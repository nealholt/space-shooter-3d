extends Node3D

# NOTE: Particles disappear and then sometimes annoyingly reappear
# when the camera moves away and then moves back to them. The issue
# can be addressed under Drawing -> Visibility AABB
# See also: https://docs.godotengine.org/en/stable/classes/class_aabb.html#class-aabb
# And: https://forum.godotengine.org/t/regarding-off-camera-particle-emision/27366

func start_emitting() -> void:
	for n in get_children():
		n.set_emitting(true)

func stop_emitting() -> void:
	for n in get_children():
		n.set_emitting(false)

# Turn on one_shot
func last_time() -> void:
	for n in get_children():
		n.one_shot = true
