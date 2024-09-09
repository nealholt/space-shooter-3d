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
		# This triggers the _on_timer_timeout function
		# which calls stop()
		$Timer.stop()
	else:
		look_at(target, Vector3.UP)
		global_position -= transform.basis.z * delta * speed

func _on_timer_timeout() -> void:
	stop()

func stop() -> void:
	# Shutdown further movement
	set_physics_process(false)
	# Go invisible
	$MeshInstance3D.visible = false
	# Damage target if there is one
	if damagee != null and damagee.is_in_group("damageable"):
		damagee.damage(1)
	damagee = null
