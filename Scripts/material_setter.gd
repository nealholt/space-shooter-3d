class_name BlenderModel extends Node3D

func apply_material(filename:String) -> void:
	$Cube.set_surface_override_material(0, load(filename))
