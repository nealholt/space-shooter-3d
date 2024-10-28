extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# This is needed for the camera to work
	Global.player = $Player
