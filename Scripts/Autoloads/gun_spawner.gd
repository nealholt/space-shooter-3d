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
var gun_array:Array[PackedScene] = [
	load("res://Scenes/Guns/gun.tscn"),
	load("res://Scenes/Guns/burst_gun.tscn"),
	load("res://Scenes/Guns/hit_scan_gun.tscn"),
	load("res://Scenes/Guns/laser_gun.tscn")
	]

enum GUN_TYPE {GUN, BURST, HITSCAN, LASER, NO_GUN}

func new_gun(gt:GUN_TYPE, bt:BulletSpawner.BULLET_TYPE, my_parent:Node3D) -> Gun:
	# Create a new gun
	var g := gun_array[int(gt)].instantiate()
	g.bullet_type = bt
	# Attach it to parent
	my_parent.add_child(g)
	return g
