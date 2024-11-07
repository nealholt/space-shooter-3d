extends Gun
class_name LaserGun

# Source:
# https://www.youtube.com/watch?v=8QumOFwX9Z0
# Godot 4: 3D Laser Tutorial
# by ConnorFoo
# With modifications and comments by Neal Holtschulte
@onready var beam_mesh := $BeamMesh
@onready var end_particles := $EndParticles
@onready var beam_particles := $BeamParticles

# Damage per second when the beam is at full radius
@export var damage_max:float = 20.0

@export var ray_length:float = 400.0

@export var power_on_time:float = 5.0 # Seconds
@export var power_off_time:float = 5.0 # Seconds

var tween:Tween
var beam_radius:float = 0.5

var is_on:bool = false
var stay_on:bool = false

var dont_interrupt:bool = false


func _ready():
	super._ready()
	ray.target_position.y = -ray_length
	# The following chunk of code sets the beam
	# to start in its deactivated state.
	end_particles.emitting = false
	beam_particles.emitting = false
	set_process(false)
	is_on = false
	ray.enabled = false
	visible = false
	beam_mesh.mesh.top_radius = 0.0
	beam_mesh.mesh.bottom_radius = 0.0
	beam_particles.process_material.scale_min = 0.0
	end_particles.process_material.scale_min = 0.0
	damage = 0.0
	
	if !ray:
		printerr('This gun requires an attached RayCast3D child that is connect to the ray export variable.')
	# Disable the ray for efficiency. Otherwise the
	# ray checks for collisions on every physics
	# update. Instead, only check for collisions
	# when the gun fires using force_raycast_update
	ray.enabled = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Default cast point
	var cast_point:Vector3 = Vector3(0, -ray_length, 0)
	# Check for actual collision
	if ray.is_colliding():
		deal_damage(ray.get_collider(), delta)
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
	# Power down the beam unless the player is holding
	# the trigger to make it stay on
	if !stay_on:
		beam_off(power_off_time)
	stay_on = false


# Override parent class's shoot_actual
func shoot_actual() -> void:
	# Activate the beam if it's not already on
	if !is_on:
		beam_on(power_on_time)
	stay_on = true


func deal_damage(collider, delta:float) -> void:
	if collider.is_in_group("damageable"):
		#print("dealing damage %f" % (damage*delta))
		collider.damage(damage*delta, data.shooter)


# Time is the duration of the activation animation.
# Make it large for slow activation, small for quick.
func beam_on(time:float) -> void:
	# Prevent this func from being called again
	# until it's finished.
	if dont_interrupt:
		return
	dont_interrupt = true
	# Set all settings to turn on the beam
	ray.enabled = true
	is_on = true
	set_process(true)
	tween = create_tween()
	visible = true
	end_particles.emitting = true
	beam_particles.emitting = true
	# set_parallel causes the following tween_property
	# commands to execute in parallel. In sequence is
	# the default.
	tween.set_parallel(true)
	tween.tween_property(self, "damage", damage_max, time)
	tween.tween_property(beam_mesh.mesh, "top_radius", beam_radius, time)
	tween.tween_property(beam_mesh.mesh, "bottom_radius", beam_radius, time)
	tween.tween_property(beam_particles.process_material, "scale_min", 1.0, time)
	tween.tween_property(end_particles.process_material, "scale_min", 1.0, time)
	# "await" pauses the current thread of execution
	# until a signal is received. Here we await
	# tween.finished before proceeding.
	# https://gdscript.com/solutions/coroutines-and-yield/
	await tween.finished
	dont_interrupt = false


# Time is the duration of the deactivation animation.
# Make it large for slow deactivation, small for quick.
func beam_off(time:float) -> void:
	# Prevent this func from being called again
	# until it's finished.
	if dont_interrupt:
		return
	dont_interrupt = true
	# Set all settings to turn off the beam
	tween = create_tween()
	# set_parallel causes the following tween_property
	# commands to execute in parallel. In sequence is
	# the default.
	tween.set_parallel(true)
	tween.tween_property(self, "damage", 0.0, time)
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
	set_process(false)
	is_on = false
	ray.enabled = false
	# Give it another half sec to let the current
	# particles time out.
	await get_tree().create_timer(0.5).timeout
	visible = false
	dont_interrupt = false


# Override parent class's activate
func activate() -> void:
	#visible = true
	#set_process(true)
	#set_physics_process(true)
	if reticle:
		reticle.show()
	if ray:
		ray.enabled = true
