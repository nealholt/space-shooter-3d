extends Node3D
class_name Projectile

# Bullets and missiles and all projectiles inherit
# from this class.

@export var speed:float = 1000.0
var velocity : Vector3

@export var damage:float = 1.0
@export var time_out:float = 2.0 #seconds

# Data on shooter and target:
var data:ShootData

# Different spark effects depending on what gets hit
@export var sparks : PackedScene
@export var shieldSparks : PackedScene
# Bullet hole decal
@export var bullet_hole_decal : PackedScene

# Every bullet has this number of frames during which
# the bullet will permanently ignore any shields it
# collides with during those frames. This allows
# bullets that are fired from within shields to
# ignore the shield.
# 2 frames suffices because collisions are only
# detected when an area is entered.
# Why doesn't 1 suffice? Don't know. But 2 seemed
# to be the magic number.
# This may need altered for raycast bullets.
var shield_grace_frames:int = 2


func _ready() -> void:
	#print("bullet created")
	# Give the bullet a default velocity.
	# Useful for testing even if the velocity
	# is updated each frame
	velocity = -global_transform.basis.z * speed
	$Timer.start(time_out)


# This is called by the gun that shoots the bullet.
# The gun passes in a ShootData object that specifies
# a variety of bullet attributes.
func set_data(dat:ShootData) -> void:
	damage = dat.damage
	# Point the projectile in the given direction
	global_transform = dat.gun.global_transform
	# Set velocity
	velocity = -transform.basis.z * speed
	# Randomize angle that bullet comes out. I'm cutting
	# spread in half so that a 10 degree spread is truly
	# 10 degrees, not plus or minus 10 degrees.
	var spread:float = deg_to_rad(dat.spread_deg/2.0)
	rotate_x(randf_range(-spread, spread))
	rotate_y(randf_range(-spread, spread))
	# Set velocity, but global this time!
	velocity = -global_transform.basis.z * speed


func get_range() -> float:
	return speed * time_out


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Move forward
	global_position += velocity * delta


func damage_and_die(body):
	# In order to fire from within a shield, we need
	# to ignore immediate collisions.
	if 0 < shield_grace_frames and body.get_groups().has("shield"):
		shield_grace_frames -= 1
		return
	# Damage what was hit
	#https://www.youtube.com/watch?v=LuUjqHU-wBw
	if body.is_in_group("damageable"):
		#print("dealt damage")
		body.damage(damage)
	# Make a spark
	# https://www.udemy.com/course/complete-godot-3d/learn/lecture/41088252#questions/21003762
	var spark = null
	if body.is_in_group("shield") and shieldSparks:
		spark = shieldSparks.instantiate()
	elif sparks:
		spark = sparks.instantiate()
	if spark:
		get_tree().get_root().add_child(spark)
		spark.global_position = global_position
		#spark.global_transform.basis.z = -area.global_transform.basis.z
		#spark.global_transform = area.global_transform
		spark.transform = transform
		#spark.rotate_y(deg_to_rad(-90))
		#spark.rotate_x(deg_to_rad(90))
	#Delete bullets that strike a body
	Callable(queue_free).call_deferred()


func _on_timer_timeout() -> void:
	#print('bullet timed out')
	queue_free()
