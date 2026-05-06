extends Camera3D

# Setting this speed to 1, or any low value, is perfect
# for getting a stunned effect. (Not yet implemented)
@export var speed := 44.0

# https://www.udemy.com/course/complete-godot-3d/learn/lecture/40979546#questions
func _physics_process(delta: float) -> void:
	var weight := clampf(delta*speed, 0.0, 1.0)
	global_transform = global_transform.interpolate_with(
		get_parent().global_transform, weight
	)
	# For now just snap to player location, but later
	# play around with interpolating or lerping this too
	# to get that acceleration affect
	global_position = get_parent().global_position
