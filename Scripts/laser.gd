extends Node3D

# Source:
# https://www.youtube.com/watch?v=8QumOFwX9Z0
# Godot 4: 3D Laser Tutorial
# by ConnorFoo
# With modifications and comments by Neal Holtschulte
@onready var ray := $RayCast3D
@onready var beam_mesh := $BeamMesh
@onready var end_particles := $EndParticles
@onready var beam_particles := $BeamParticles

@export var ray_length:float = 100.0

var tween:Tween
var beam_radius:float = 0.5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ray.target_position.y = -ray_length
	# TODO TESTING. Delete this
	await get_tree().create_timer(2.0).timeout
	deactivate(2)
	await get_tree().create_timer(4.0).timeout
	activate(2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Default cast point
	var cast_point:Vector3 = Vector3(0, -ray_length, 0)
	# Check for actual collision
	ray.force_raycast_update()
	if ray.is_colliding():
		cast_point = to_local(ray.get_collision_point())
	# Position the beam mesh
	beam_mesh.mesh.height = cast_point.y
	beam_mesh.position.y = cast_point.y/2.0
	#position particles
	end_particles.position.y = cast_point.y
	beam_particles.position.y = cast_point.y/2.0
	
	# Get distance to end of beam
	var dist:float = cast_point.length()
	# Adjust lifetime of beam particles to end
	# roughly at target. Assumes a particle speed
	# of 40 meters per second...
	# ...for some reason there's a further
	# divide by two. I'm not sure why. I'm not sure
	# why there's a divide by 2 for the mesh and
	# particle positions above.
	beam_particles.lifetime = dist/80.0
	
	# 10 particles per 1 meter of beam
	# up to a max of 500.
	var particle_amount:int = snapped(abs(cast_point.y)*10, 1)
	particle_amount = clampi(particle_amount, 1, 500)
	# Position beam particles
	beam_particles.process_material.set_emission_box_extents(
		Vector3(beam_mesh.mesh.top_radius, abs(cast_point.y)/2, beam_mesh.mesh.top_radius)
	)


# Time is the duration of the activation animation.
# Make it large for slow activation, small for quick.
func activate(time:float) -> void:
	set_process(true)
	tween = create_tween()
	visible = true
	end_particles.emitting = true
	beam_particles.emitting = true
	# set_parallel causes the following tween_property
	# commands to execute in parallel. In sequence is
	# the default.
	tween.set_parallel(true)
	tween.tween_property(beam_mesh.mesh, "top_radius", beam_radius, time)
	tween.tween_property(beam_mesh.mesh, "bottom_radius", beam_radius, time)
	tween.tween_property(beam_particles.process_material, "scale_min", 1.0, time)
	tween.tween_property(end_particles.process_material, "scale_min", 1.0, time)
	# "await" pauses the current thread of execution
	# until a signal is received. Here we await
	# tween.finished before proceeding.
	# https://gdscript.com/solutions/coroutines-and-yield/
	await tween.finished


# Time is the duration of the deactivation animation.
# Make it large for slow deactivation, small for quick.
func deactivate(time:float) -> void:
	tween = create_tween()
	end_particles.emitting = true
	beam_particles.emitting = true
	# set_parallel causes the following tween_property
	# commands to execute in parallel. In sequence is
	# the default.
	tween.set_parallel(true)
	tween.tween_property(beam_mesh.mesh, "top_radius", 0.0, time)
	tween.tween_property(beam_mesh.mesh, "bottom_radius", 0.0, time)
	tween.tween_property(beam_particles.process_material, "scale_min", 0.0, time)
	tween.tween_property(end_particles.process_material, "scale_min", 0.0, time)
	# "await" pauses the current thread of execution
	# until a signal is received. Here we await
	# tween.finished before proceeding.
	# https://gdscript.com/solutions/coroutines-and-yield/
	await tween.finished
	end_particles.emitting = false
	beam_particles.emitting = false
	# Give it another half sec to let the current
	# particles time out.
	await get_tree().create_timer(0.5).timeout
	visible = false
	set_process(false)
