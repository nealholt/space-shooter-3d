class_name Level extends Node3D

func _ready() -> void:
	Global.environment = $WorldEnvironment.environment
	EventsBus.environment_set.emit()
	
	# Search for an asteroid field child. If found,
	# generate the asteroid field.
	# This is done instead of using the _ready function
	# in asteroid_field.gd because the player needs
	# to be instantiated before the asteroid field.
	for c in get_children():
		if c is AsteroidField:
			c.generate_field()
