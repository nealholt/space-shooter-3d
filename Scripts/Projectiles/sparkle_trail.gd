class_name SparkleTrailVisual extends Node3D
# This is purely visual. I boxed up a contrail and a couple
# GPU particles into a little scene and wrote this script
# so that the particles stop emitting and the contrails
# fade out after the projectile this is attached to hits
# its target.

@onready var contrail: Trail3D = $Contrail
@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D
@onready var gpu_particles_3d_2: GPUParticles3D = $GPUParticles3D2

# This is called by the projectile's wrap_up() function
func wrap_up() -> void:
	gpu_particles_3d.one_shot = true
	gpu_particles_3d.emitting = false
	
	gpu_particles_3d_2.one_shot = true
	gpu_particles_3d_2.emitting = false
	
	contrail._lifeSpan = contrail._lifeSpan/10.0
