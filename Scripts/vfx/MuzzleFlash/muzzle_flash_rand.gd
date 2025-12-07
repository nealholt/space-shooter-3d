# The tutorial I originally followed for all the
# GPU Particles was:
# GODOT VFX - Muzzle Flash Effect Tutorial
# by Gabriel Aguiar Prod.
# at https://www.youtube.com/watch?v=YuCvAwZ3OlQ
# Modifications and scripts by Neal Holtschulte
extends Node3D

@onready var planes_group: Node3D = $PlanesGroup
@onready var cones_group: Node3D = $ConesGroup

var emitter_list : Array
var planes_count : int
var cones_count : int
var temp_emitter :GPUParticles3D

func _ready() -> void:
	# Add all GPU Particles children to the
	# emitter list.
	for c in get_children():
		if c is GPUParticles3D:
			emitter_list.push_back(c)
	# Count children of planes and cones
	# Subtract one because randi_range's upper end
	# is inclusive.
	planes_count = planes_group.get_child_count()-1
	cones_count = cones_group.get_child_count()-1
	if planes_count < 0:
		push_error('MuzzleFlash planes group must have at least one GPUParticles3D as child.')
	if cones_count < 0:
		push_error('MuzzleFlash planes group must have at least one GPUParticles3D as child.')

func play() -> void:
	# Activate all the standard emitters
	for gpu_particle in emitter_list:
		gpu_particle.set_emitting(true)
	# Activate one random plane and one random cone
	planes_group.get_child(randi_range(0,planes_count)).set_emitting(true)
	cones_group.get_child(randi_range(0,cones_count)).set_emitting(true)
