extends Node3D

@export var bullet: PackedScene # What sort of bullet to fire

func _process(_delta: float) -> void:
	# Fire a bullet
	if Input.is_action_just_released("ui_accept"):
		var b = bullet.instantiate()
		get_tree().get_root().add_child(b)
		b.speed = 250.0 # Slow it down
		b.set_data(self)
