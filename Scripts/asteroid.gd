extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO get_shader_parameter is not working
	var heightmap = $Sphere.mesh.material.get_shader_parameter("Texture2D") as NoiseTexture2D
	var noise = heightmap.noise as FastNoiseLite
	noise.seed = randi()
