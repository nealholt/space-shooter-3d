extends Camera3D

# This probably shouldn't be needed, but it is.

func _ready() -> void:
	Global.current_camera = self
