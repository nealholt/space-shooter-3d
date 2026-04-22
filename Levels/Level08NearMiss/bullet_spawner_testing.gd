extends Node3D

func _process(_delta: float) -> void:
	# Fire a bullet using "spacebar"
	if Input.is_action_just_released("ui_accept"):
		var sd:=ShootData.new()
		sd.shooter = self
		$Gun.shoot(sd)
