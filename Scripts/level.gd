class_name Level extends Node3D

func _ready() -> void:
	Global.environment = $WorldEnvironment.environment
	EventsBus.environment_set.emit()
