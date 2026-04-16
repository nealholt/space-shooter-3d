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

# Guns call this to get a made-to-order bullet
func new_bullet(bt:BULLET_TYPE) -> Projectile:
	var projectile := bullet_array[int(bt)].instantiate()
	return projectile
