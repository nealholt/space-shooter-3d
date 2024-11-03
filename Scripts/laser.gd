extends RayCast3D

# Source:
# https://www.youtube.com/watch?v=8QumOFwX9Z0
# Godot 4: 3D Laser Tutorial
# by ConnorFoo
@onready var beam_mesh := $BeamMesh
@onready var end_particles := $EndParticles
@onready var beam_particles := $BeamParticles

var tween:Tween
var beam_radius:float = 0.5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO TESTING. Delete this
	await get_tree().create_timer(2.0).timeout
	deactivate(1)
	await get_tree().create_timer(2.0).timeout
	activate(1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var cast_point
	force_raycast_update()
	
	if is_colliding():
		cast_point = to_local(get_collision_point())
		
		beam_mesh.mesh.height = cast_point.y
		beam_mesh.position.y = cast_point.y/2.0
		
		end_particles.position.y = cast_point.y
		
		beam_particles.position.y = cast_point.y/2.0
		
		# 50 particles per 1 meter of beam
		var particle_amount:int = snapped(abs(cast_point.y)*50, 1)
		if particle_amount > 1:
			beam_particles.amount = particle_amount
		else:
			beam_particles.amount = 1
		
		beam_particles.process_material.set_emission_box_extents(
			Vector3(beam_mesh.mesh.top_radius, abs(cast_point.y)/2, beam_mesh.mesh.top_radius)
		)


func activate(time:float) -> void:
	#tween = Global.main_scene.main_3d.create_tween() #TODO
	tween = get_tree().create_tween()
	visible = true
	end_particles.emitting = true
	beam_particles.emitting = true
	tween.set_parallel(true)
	tween.tween_property(beam_mesh.mesh, "top_radius", beam_radius, time)
	tween.tween_property(beam_mesh.mesh, "bottom_radius", beam_radius, time)
	tween.tween_property(beam_particles.process_material, "scale_min", 1.0, time)
	tween.tween_property(end_particles.process_material, "scale_min", 1.0, time)
	await tween.finished


func deactivate(time:float) -> void:
	#tween = Global.main_scene.main_3d.create_tween() #TODO
	tween = get_tree().create_tween()
	end_particles.emitting = true
	beam_particles.emitting = true
	tween.set_parallel(true)
	tween.tween_property(beam_mesh.mesh, "top_radius", 0.0, time)
	tween.tween_property(beam_mesh.mesh, "bottom_radius", 0.0, time)
	tween.tween_property(beam_particles.process_material, "scale_min", 0.0, time)
	tween.tween_property(end_particles.process_material, "scale_min", 0.0, time)
	await tween.finished
	visible = false
	end_particles.emitting = false
	beam_particles.emitting = false
