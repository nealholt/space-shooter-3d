extends Node3D
class_name BulletBit

# I thought I'd go ahead and animate the shotgun
# with a bunch of pellets that zip from the
# shooter to the collision point.

# This is currently exclusively used with the
# laser shotgun.

@export var speed:float = 400.0
var target : Vector3

var damagee # Thing to deal damage to.
# I'm moving damage dealing from laser_shotgun
# into here so that damage is dealt on pseudo
# impact rather than instantaneously

func _ready() -> void:
	set_physics_process(false)
	$MeshInstance3D.visible = false

func set_up(start:Vector3, end:Vector3, victim) -> void:
	damagee = victim
	set_physics_process(true)
	$MeshInstance3D.visible = true
	target = end
	global_position = start
	# Calculate time out so it looks like the bullet
	# disappears at impact point
	var dist = start.distance_to(end)
	var time = dist/speed
	$Timer.start(time)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Otherwise there are errors when using look_at
	# because the bullet is occasionally too close
	# to its target.
	# https://forum.godotengine.org/t/process-node-origin-and-target-are-in-the-same-position-look-at-failed-godot-4-version/4357/2
	if global_position.is_equal_approx(target):
		stop()
	else:
		look_at(target, Vector3.UP)
		global_position -= transform.basis.z * delta * speed

func _on_timer_timeout() -> void:
	stop()

func stop() -> void:
	set_physics_process(false)
	$MeshInstance3D.visible = false
	if damagee != null:
		# If can deal damage, do so
		if damagee.is_in_group("damageable"):
			damagee.damage(1)
		damagee = null
