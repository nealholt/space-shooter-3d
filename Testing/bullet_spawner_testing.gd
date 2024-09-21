extends Node3D

func _process(_delta: float) -> void:
	# Fire a bullet
	if Input.is_action_just_released("ui_accept"):
		$Gun.shoot(self)
