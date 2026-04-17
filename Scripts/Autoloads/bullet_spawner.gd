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
	load("res://Scenes/Projectiles/bullet_ray_big.tscn")
	]

enum BULLET_TYPE {BASIC_RAY, SEEKING_MISSILE, 
	LASER_GUIDED_MISSILE, PROXY_FUSE, SHOTGUN_PELLET, TIMED_FUSE,
	GIANT_RAY}

var generic_projectile:PackedScene = load('res://Scenes/Projectiles/projectile.tscn')

var ray4projectiles:PackedScene = load('res://Scenes/Projectiles/ray_cast_4_projectiles.tscn')

var laser_bolt:PackedScene = load('res://Assets/Projectiles/Bullets/green_laser_bolt.tscn')
var laser_bolt_giant:PackedScene = load('res://Assets/Projectiles/Bullets/green_laser_bolt_giant.tscn')


# Guns call this to get a made-to-order bullet
func new_bullet(bt:BULLET_TYPE) -> Projectile:
	match bt:
		BULLET_TYPE.BASIC_RAY:
			return _get_ray_bolt(bt)
		BULLET_TYPE.GIANT_RAY:
			return _get_ray_bolt(bt)
		BULLET_TYPE.SEEKING_MISSILE:
			pass # TODO LEFT OFF HERE
		BULLET_TYPE.LASER_GUIDED_MISSILE:
			pass
		BULLET_TYPE.PROXY_FUSE:
			pass
		BULLET_TYPE.SHOTGUN_PELLET:
			pass
		BULLET_TYPE.TIMED_FUSE:
			pass
		_: # Default / Otherwise
			pass
	var projectile := bullet_array[int(bt)].instantiate()
	return projectile


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
