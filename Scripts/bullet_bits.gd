extends Node3D
class_name BulletBit

# I thought I'd go ahead and animate the shotgun
# with a bunch of pellets that zip from the
# shooter to the collision point.

# This is currently exclusively used with the
# laser shotgun.

@onready var bullet_hole_decal = preload("res://Assets/Decals/bullet_hole.tscn")
@export var speed:float = 500.0
var target : Vector3
var collision_normal:Vector3 # For orienting decal
var damagee # Thing to deal damage to.
# I'm moving damage dealing from laser_shotgun
# into here so that damage is dealt on pseudo
# impact rather than instantaneously

func set_up(start:Vector3, end:Vector3, collision_norm:Vector3, victim:Node3D) -> void:
	global_position = start
	target = end
	collision_normal = collision_norm
	damagee = victim
	look_at(target, Vector3.UP) # Orient toward target
	# Calculate time out so it looks like the bullet
	# disappears at impact point
	var dist = global_position.distance_to(target)
	$Timer.start(dist/speed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Move toward target
	global_position -= transform.basis.z * delta * speed

func stop() -> void:
	# Damage target if there is one
	if damagee != null:
		stick_decal()
		if damagee.is_in_group("damageable"):
			damagee.damage(1)
		damagee = null
	queue_free()

# Source:
# https://www.youtube.com/watch?v=8vFOOglWW3w
func stick_decal() -> void:
	#Stick a decal on the target or on whatever was hit
	var decal = bullet_hole_decal.instantiate()
	# Parent decal to root, otherwise there can be
	# weird scaling if attaching as a child of a scaled
	# node.
	get_tree().root.add_child(decal)
	# Position and orient the decal
	decal.global_position = target
	if collision_normal == Vector3.DOWN:
		decal.rotation_degrees.x = 90
	else:
		decal.look_at(global_position - collision_normal, Vector3(0,1,0))


func _on_timer_timeout() -> void:
	stop()
