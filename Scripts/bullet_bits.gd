extends Node3D
class_name BulletBit

# I thought I'd go ahead and animate the shotgun
# with a bunch of pellets that zip from the
# shooter to the collision point.

# This is currently exclusively used with the
# laser shotgun.

@onready var bullet_hole_decal = preload("res://Assets/Decals/bullet_hole.tscn")
@export var speed:float = 100.0 #TODO 400.0
var speed_sqd:float = speed*speed
var target : Vector3
var ray : RayCast3D
var time_to_target:float

var damagee # Thing to deal damage to.
# I'm moving damage dealing from laser_shotgun
# into here so that damage is dealt on pseudo
# impact rather than instantaneously

func _ready() -> void:
	set_physics_process(false)
	$MeshInstance3D.visible = false

func set_up(start:Vector3, raycast:RayCast3D) -> void:
	# This if should trigger if the bulletbit is fired
	# again before reaching previous target.
	if $MeshInstance3D.visible and damagee != null:
		# This is possible because bulletbits don't damage
		# their target until they reach it. Solutions include:
		# 1. just deal the damage here and don't worry
		# that the bullet bits are getting recalled to
		# another shot.
		# 2. Fire rate low enough and bullet bit speed high
		# enough that this can't happen.
		# 3. Two or more sets of bullet bits that are
		# alternately used by the gun so one set can be
		# enroute to target when the next one fires.
		# 4. Cut this premature optimization bullshit
		# and just spawn and queue free new bulletbits
		# the same as every other bullet instead of
		# reusing them.
		printerr('set_up called on BulletBit before previous target was dealt damage')
	ray = raycast
	damagee = ray.get_collider()
	set_physics_process(true)
	$MeshInstance3D.visible = true
	global_position = start

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	update_target()
	# Check this condition otherwise there are
	# errors when using look_at because the bullet
	# is occasionally too close to its target.
	# https://forum.godotengine.org/t/process-node-origin-and-target-are-in-the-same-position-look-at-failed-godot-4-version/4357/2
	# Also stop if within 10000th of a second of reaching target
	if global_position.is_equal_approx(target) or time_to_target < 0.0001:
		stop()
	else:
		look_at(target, Vector3.UP)
		global_position -= transform.basis.z * delta * speed

func stop() -> void:
	# Shutdown further movement
	set_physics_process(false)
	# Go invisible
	$MeshInstance3D.visible = false
	# Damage target if there is one
	if damagee != null:
		stick_decal()
		if damagee.is_in_group("damageable"):
			damagee.damage(1)
	damagee = null

# Source:
# https://www.youtube.com/watch?v=8vFOOglWW3w
func stick_decal() -> void:
	#Stick a decal on the target or on whatever was hit
	var decal = bullet_hole_decal.instantiate()
	# Parent decal to root, otherwise there can be
	# weird scaling if attaching as a child of a scaled
	# node.
	get_tree().root.add_child(decal)
	#decal.global_position = ray.get_collision_point()
	decal.global_position = target
	var collision_normal = ray.get_collision_normal()
	if collision_normal == Vector3.DOWN:
		decal.rotation_degrees.x = 90
	else:
		decal.look_at(global_position - collision_normal, Vector3(0,1,0))

func update_target() -> void:
	# For some reason I have to keep updating this
	# otherwise the bullets fly to and the decals
	# stick at outdated points, literally the previous
	# location of the raycast. I cannot figure out
	# why so this is my fix.
	if ray.is_colliding():
		target = ray.get_collision_point()
	else:
		target = global_position+ray.global_transform.basis.z * ray.target_position.z
	# Calculate time out so it looks like the bullet
	# disappears at impact point
	var dist = global_position.distance_squared_to(target)
	time_to_target = dist/speed_sqd
