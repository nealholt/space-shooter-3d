extends Node3D

func start_emitting() -> void:
	for n in get_children():
		n.set_emitting(true)

func stop_emitting() -> void:
	for n in get_children():
		n.set_emitting(false)
