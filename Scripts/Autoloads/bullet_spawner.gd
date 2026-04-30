extends Node

# The DUMMY_PLACEHOLDER below is used so the enums
# don't all get messed up / re-ordered.
# If / when you ever add in a new bullet, replace the
# dummy variable.
enum BULLET_TYPE {MISSILE, DUMMY_PLACEHOLDER, BASIC_RAY, SEEKING_MISSILE, 
	LASER_GUIDED_MISSILE, PROXY_FUSE, TIMED_FUSE,
	GIANT_RAY, SPARKLE}

# According to this: https://forum.godotengine.org/t/parse-error-referenced-non-existent-resource/95356/5
# "you shouldn’t use preload in autoload script because there will
# be a 'race' of loading files and your program will try to load
# non referenced file or things like that."
# The error is this "Parse Error: referenced non-existent resource"
# and it can be caused by circular references.
# See also: https://www.reddit.com/r/godot/comments/12iovkb/packedscene_wont_load_referenced_nonexistent/
# This is also the reason I separated the gun_spawner and
# the bullet_spawner---because guns were referencing the
# gun spawner in order to request bullets... though I'm not
# certain this separation was necessary. The change from preload
# to load might have fixed the issue.
var generic_projectile:PackedScene = load('res://Scenes/Projectiles/projectile.tscn')

var missile_scene:PackedScene = load("res://Scenes/Projectiles/missile.tscn")

# Damage-dealing explosion
var damaging_explosion:PackedScene = load('res://Scenes/explosion_damage_dealing.tscn')

# Meshes. Purely visual.
var laser_bolt:PackedScene = load('res://Assets/Projectiles/Bullets/green_laser_bolt.tscn')
var laser_bolt_giant:PackedScene = load('res://Assets/Projectiles/Bullets/green_laser_bolt_giant.tscn')
var pellet_red:PackedScene = load('res://Assets/Projectiles/Bullets/pellet_red.tscn')
# Contrails. Purely visual
var contrail:PackedScene = load('res://Scenes/contrail.tscn')
# Larger contrail and some flashing GPU particles
var sparkle_trail:PackedScene = load('res://Assets/Projectiles/sparkle.tscn')

# Controllers for seeking behaviors
var physics_seek:PackedScene = load('res://Scenes/MovementControllers/physics_seek_controller.tscn')
var simple_seek:PackedScene = load('res://Scenes/MovementControllers/simple_seek_controller.tscn')


# Guns call this to get a made-to-order bullet
func new_bullet(bt:BULLET_TYPE) -> Projectile:
	var projectile : Projectile
	match bt:
		BULLET_TYPE.MISSILE:
			projectile = missile_scene.instantiate()
		BULLET_TYPE.DUMMY_PLACEHOLDER: # Replace me when you have a chance
			projectile = null
		BULLET_TYPE.BASIC_RAY:
			projectile = _get_ray_bolt(bt)
		BULLET_TYPE.GIANT_RAY:
			projectile = _get_ray_bolt(bt)
		BULLET_TYPE.SEEKING_MISSILE:
			projectile = _get_seeking_contrail(bt)
		BULLET_TYPE.LASER_GUIDED_MISSILE:
			projectile = _get_seeking_contrail(bt)
		BULLET_TYPE.PROXY_FUSE:
			projectile = _get_proxy_fuse()
		BULLET_TYPE.TIMED_FUSE:
			projectile = _get_timed_fuse()
		BULLET_TYPE.SPARKLE:
			projectile = _get_sparkle_trail()
		_: # Default / Otherwise
			push_error('Unrecognized bullet type ',bt)
	return projectile


# This gets one of two raycast bullet options. The only
# difference is the mesh that is used, but the meshes come
# in different sizes, which in turn effects the ray cast size.
func _get_ray_bolt(bt:BULLET_TYPE) -> Projectile:
	var projectile := generic_projectile.instantiate()
	# Choose the mesh
	var mesh:MeshInstance3D
	match bt:
		BULLET_TYPE.BASIC_RAY:
			mesh = laser_bolt.instantiate()
		BULLET_TYPE.GIANT_RAY:
			mesh = laser_bolt_giant.instantiate()
		_: # Default / Otherwise
			push_error('Unrecognized bullet type ',bt)
	# Attach mesh to projectile root
	projectile.add_child(mesh)
	# Make the ray at least as long as the mesh
	# print(mesh.get_mesh().get_height())
	var mesh_height:float = mesh.get_mesh().get_height()
	projectile.projectile_length = mesh_height
	projectile.does_ricochet = false
	# Reposition mesh to start at the same origin as the ray
	mesh.position = Vector3(0.0, 0.0, -mesh_height/2.0)
	return projectile


# This gets one of two seeking projectile options, both of
# which only have a contrail as their visual component. The only
# difference is that one auto-seeks a target and the other is
# laser guided.
func _get_seeking_contrail(bt:BULLET_TYPE) -> Projectile:
	var projectile := generic_projectile.instantiate()
	var contra := contrail.instantiate()
	var control := physics_seek.instantiate()
	# Parameterize the physics_seek
	match bt:
		BULLET_TYPE.SEEKING_MISSILE:
			control.is_laser_guided = false
		BULLET_TYPE.LASER_GUIDED_MISSILE:
			control.is_laser_guided = true
		_: # Default / Otherwise
			push_error('Unrecognized bullet type ',bt)
	# Attach physics seek controller
	projectile.add_child(control)
	control.steer_force = 200.0
	projectile.does_ricochet = false
	# Attach contrail
	projectile.add_child(contra)
	# Parameterize projectile
	projectile.speed = 250.0
	projectile.time_out = 4.0
	projectile.sparks = VisualEffectSetting.VISUAL_EFFECT_TYPE.NO_EFFECT
	projectile.shieldSparks = VisualEffectSetting.VISUAL_EFFECT_TYPE.NO_EFFECT
	projectile.autotarget = true
	projectile.roll_amount = 10.0
	return projectile


func _get_timed_fuse() -> Projectile:
	var projectile := generic_projectile.instantiate()
	var mesh := pellet_red.instantiate()
	projectile.does_ricochet = false
	# Attach mesh
	projectile.add_child(mesh)
	# Parameterize projectile
	projectile.sparks = VisualEffectSetting.VISUAL_EFFECT_TYPE.NO_EFFECT
	projectile.shieldSparks = VisualEffectSetting.VISUAL_EFFECT_TYPE.NO_EFFECT
	projectile.damaging_explosion = damaging_explosion
	projectile.explode_on_timeout = true
	return projectile


func _get_proxy_fuse() -> Projectile:
	var projectile := generic_projectile.instantiate()
	# Create area with collision shape
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = SphereShape3D.new()
	var a := Area3D.new()
	a.add_child(collision_shape)
	a.monitorable = false # The area monitors, it doesn't need others monitoring it
	a.collision_layer = 0 # I am
	a.collision_mask = Global.EVERYTHING_COLL_LAYER # I hit
	a.scale = Vector3(3.0, 3.0, 3.0)
	projectile.add_child(a)
	projectile.does_ricochet = false
	# Create mesh
	var mesh := pellet_red.instantiate()
	projectile.add_child(mesh)
	# Parameterize projectile
	projectile.sparks = VisualEffectSetting.VISUAL_EFFECT_TYPE.NO_EFFECT
	projectile.shieldSparks = VisualEffectSetting.VISUAL_EFFECT_TYPE.NO_EFFECT
	projectile.damaging_explosion = damaging_explosion
	projectile.explode_on_timeout = true
	return projectile


func _get_sparkle_trail() -> Projectile:
	var projectile := generic_projectile.instantiate()
	var visuals := sparkle_trail.instantiate()
	var control := physics_seek.instantiate()
	# Attach physics seek controller
	projectile.add_child(control)
	control.steer_force = 2500.0
	projectile.does_ricochet = false
	# Attach contrail and sparkle
	projectile.add_child(visuals)
	# Parameterize projectile
	projectile.time_out = 5.0
	projectile.deathExplosion = VisualEffectSetting.VISUAL_EFFECT_TYPE.SINGLE_EXPLOSION_8X
	projectile.wrap_up_time = 5.0
	return projectile
