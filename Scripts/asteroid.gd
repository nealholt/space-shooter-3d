extends Node3D

@export_range (10.0, 400.0) var size:float = 100.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# I tested a few relationships between jut (named
	# "size" above) and frequency, which smooths
	# the surface and found this one to result in
	# not too janky asteroids.
	var frequency:float = clampf(-size/80000.0 + 0.007, 0.001, 0.01)
	var shader_ref : ShaderMaterial = $Sphere.mesh.material
	var heightmap = shader_ref.get_shader_parameter("NoiseParam") as NoiseTexture2D
	var noise = heightmap.noise as FastNoiseLite
	noise.seed = randi()
	noise.frequency = frequency
	shader_ref.set("shader_parameter/jut_intensity", size)
	# TODO try it with and without this next bit
	# I feel like I'm doing something wrong, but I
	# think the normal needs to be the same as the
	# vertex and I don't know how else to do that
	# than to have a duplicate shader and parameterize
	# them the same way
	var heightmap2 = shader_ref.get_shader_parameter("NoiseParam2") as NoiseTexture2D
	var noise2 = heightmap2.noise as FastNoiseLite
	noise2.seed = noise.seed
	noise2.frequency = noise.frequency
	shader_ref.set("shader_parameter/jut_intensity2", size)
