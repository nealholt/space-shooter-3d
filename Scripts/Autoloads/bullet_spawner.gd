extends Node

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
var bullet_array:Array[PackedScene] = [
	load("res://Scenes/Projectiles/bullet_ray_basic.tscn"),
	load("res://Scenes/Projectiles/auto_seeking_missile.tscn"),
	load("res://Scenes/Projectiles/laser_guided_missile.tscn"),
	load("res://Scenes/Projectiles/proxy_fuse_bullet.tscn"),
	load("res://Scenes/Projectiles/shotgun_pellet.tscn"),
	load("res://Scenes/Projectiles/timed_fuse_bullet.tscn"),
	load("res://Scenes/Projectiles/bullet_ray_big.tscn"),
	load('res://Scenes/Projectiles/sparkle_trail_missile.tscn')
	]

enum BULLET_TYPE {BASIC_RAY, SEEKING_MISSILE, 
	LASER_GUIDED_MISSILE, PROXY_FUSE, SHOTGUN_PELLET, TIMED_FUSE,
	GIANT_RAY, SPARKLE}

var generic_projectile:PackedScene = load('res://Scenes/Projectiles/projectile.tscn')

# All raycast projectiles need this attached
var ray4projectiles:PackedScene = load('res://Scenes/Projectiles/ray_cast_4_projectiles.tscn')

# Meshes. Purely visual.
var laser_bolt:PackedScene = load('res://Assets/Projectiles/Bullets/green_laser_bolt.tscn')
var laser_bolt_giant:PackedScene = load('res://Assets/Projectiles/Bullets/green_laser_bolt_giant.tscn')
var pellet:PackedScene = load('res://Assets/Projectiles/Bullets/pellet.tscn')
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
		BULLET_TYPE.SHOTGUN_PELLET:
			projectile = bullet_array[int(bt)].instantiate()
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
	var r := ray4projectiles.instantiate()
	# Choose the mesh
	var mesh:MeshInstance3D
	match bt:
		BULLET_TYPE.BASIC_RAY:
			mesh = laser_bolt.instantiate()
		BULLET_TYPE.GIANT_RAY:
			mesh = laser_bolt_giant.instantiate()
		_: # Default / Otherwise
			push_error('Unrecognized bullet type ',bt)
	# Attach ray and mesh to projectile root
	projectile.add_child(r)
	projectile.add_child(mesh)
	# Make the ray at least as long as the mesh
	# print(mesh.get_mesh().get_height())
	var mesh_height:float = mesh.get_mesh().get_height()
	r.projectile_length = mesh_height
	r.does_ricochet = false
	# Reposition mesh to start at the same origin as the ray
	mesh.position = Vector3(0.0, 0.0, -mesh_height/2.0)
	return projectile


# This gets one of two seeking projectile options, both of
# which only have a contrail as their visual component. The only
# difference is that one auto-seeks a target and the other is
# laser guided.
func _get_seeking_contrail(bt:BULLET_TYPE) -> Projectile:
	var projectile := generic_projectile.instantiate()
	var r := ray4projectiles.instantiate()
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
	# Attach ray
	projectile.add_child(r)
	r.does_ricochet = false
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


# TODO There may be problems with this. More testing is needed.
func _get_timed_fuse() -> Projectile:
	var projectile := generic_projectile.instantiate()
	var r := ray4projectiles.instantiate()
	var mesh := pellet.instantiate()
	# Attach ray
	projectile.add_child(r)
	r.does_ricochet = false
	# Attach mesh
	projectile.add_child(mesh)
	# Parameterize projectile
	projectile.sparks = VisualEffectSetting.VISUAL_EFFECT_TYPE.NO_EFFECT
	projectile.shieldSparks = VisualEffectSetting.VISUAL_EFFECT_TYPE.NO_EFFECT
	projectile.damaging_explosion = load('res://Scenes/explosion_damage_dealing.tscn')
	projectile.explode_on_timeout = true
	return projectile


# TODO There may be problems with this. More testing is needed.
func _get_proxy_fuse() -> Projectile:
	var projectile := generic_projectile.instantiate()
	var a := Area3D.new()
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = SphereShape3D.new()
	a.add_child(collision_shape)
	projectile.add_child(a)
	var mesh := pellet_red.instantiate()
	projectile.add_child(mesh)
	# Parameterize projectile
	projectile.sparks = VisualEffectSetting.VISUAL_EFFECT_TYPE.NO_EFFECT
	projectile.shieldSparks = VisualEffectSetting.VISUAL_EFFECT_TYPE.NO_EFFECT
	projectile.damaging_explosion = load('res://Scenes/explosion_damage_dealing.tscn')
	projectile.explode_on_timeout = true
	return projectile


func _get_sparkle_trail() -> Projectile:
	var projectile := generic_projectile.instantiate()
	var r := ray4projectiles.instantiate()
	var visuals := sparkle_trail.instantiate()
	var control := physics_seek.instantiate()
	# Attach physics seek controller
	projectile.add_child(control)
	control.steer_force = 2500.0
	# Attach ray
	projectile.add_child(r)
	r.does_ricochet = false
	# Attach contrail and sparkle
	projectile.add_child(visuals)
	# Parameterize projectile
	projectile.time_out = 5.0
	projectile.deathExplosion = VisualEffectSetting.VISUAL_EFFECT_TYPE.SINGLE_EXPLOSION_8X
	projectile.wrap_up_time = 5.0
	return projectile
