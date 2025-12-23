extends Node

#const GUN_SCENE:PackedScene = preload("res://Scenes/Guns/gun.tscn")
#const BURST_GUN_SCENE:PackedScene = preload("res://Scenes/Guns/burst_gun.tscn")
#const HITSCAN_GUN_SCENE:PackedScene = preload("res://Scenes/Guns/hit_scan_gun.tscn")
#const LASER_GUN_SCENE:PackedScene = preload("res://Scenes/Guns/laser_gun.tscn")
#const LASER_SHOTGUN_SCENE:PackedScene = preload("res://Scenes/Guns/laser_shotgun.tscn")

# TODO Is this all the gun types? Below, are those all
# the bullet types? I don't know. I'm initially doing
# this quick and sloppy.

var gun_array:Array[PackedScene] = [
	preload("res://Scenes/Guns/gun.tscn"),
	preload("res://Scenes/Guns/burst_gun.tscn"),
	preload("res://Scenes/Guns/hit_scan_gun.tscn"),
	preload("res://Scenes/Guns/laser_gun.tscn"),
	preload("res://Scenes/Guns/laser_shotgun.tscn")
	]

enum GUN_TYPE {GUN, BURST, HITSCAN, LASER, LASER_SHOT, NO_GUN}

var bullet_array:Array[PackedScene] = [
	preload("res://Scenes/Projectiles/bullet_area_basic.tscn"),
	preload("res://Scenes/Projectiles/bullet_ray_basic.tscn"),
	preload("res://Scenes/Projectiles/auto_seeking_missile.tscn"),
	preload("res://Scenes/Projectiles/laser_guided_missile.tscn"),
	preload("res://Scenes/Projectiles/proximity_fuse_bullet.tscn"),
	preload("res://Scenes/Projectiles/shotgun_pellet.tscn"),
	preload("res://Scenes/Projectiles/timed_fuse_bullet.tscn")
	]

enum BULLET_TYPE {BASIC_AREA, BASIC_RAY, SEEKING_MISSILE, 
	LASER_GUIDED_MISSILE, PROXY_FUSE, SHOTGUN_PELLET, TIMED_FUSE}


func new_gun(gt:GUN_TYPE, bt:BULLET_TYPE, my_parent:Node3D) -> Gun:
	# Create a new gun
	var g := gun_array[int(gt)].instantiate()
	g.bullet = bullet_array[int(bt)]
	# Attach it to parent
	my_parent.add_child(g)
	return g
