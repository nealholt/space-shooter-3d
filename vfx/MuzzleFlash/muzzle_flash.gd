# The tutorial I originally followed for all the
# GPU Particles was:
# GODOT VFX - Muzzle Flash Effect Tutorial
# by Gabriel Aguiar Prod.
# at https://www.youtube.com/watch?v=YuCvAwZ3OlQ
# Modifications and scripts by Neal Holtschulte
extends Node3D

var emitter_list : Array

func _ready() -> void:
	# Add all GPU Particles children to the list
	for c in get_children():
		if c is GPUParticles3D:
			#print(c.name)
			emitter_list.push_back(c)

func play() -> void:
	for gpu_particle in emitter_list:
		gpu_particle.set_emitting(true)
