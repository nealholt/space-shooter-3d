extends Node3D
class_name Projectile

# Bullets and missiles and all projectiles inherit
# from this class.

@export var speed:float = 1000.0
var velocity : Vector3
@export var controller:Controller

@export var damage:float = 1.0
@export var time_out:float = 2.0 #seconds

# Data on shooter and target:
var data:ShootData

# Different spark effects depending on what gets hit
@export var sparks : PackedScene
@export var shieldSparks : PackedScene
# Bullet hole decal
@export var bullet_hole_decal : PackedScene

var near_miss_audio: AudioStreamPlayer3D

# Every bullet has this amount of time during which
# the bullet will permanently ignore any shields it
# collides with during those frames. This allows
# bullets that are fired from within shields to
# ignore the shield.
# About 2/100ths of a second suffices because
# collisions are only detected when an area is
# entered.
# Why doesn't 1/100th or less suffice? Don't know.
# But 2/100ths seemed to be the magic number.
# This may need altered for raycast bullets.
var shield_grace_period:float = 1.0/50.0
# NOTE: For raycasts with the "Hit From Inside"
# checkbox deselected, shield_grace_period is
# not even needed. However, you don't want
# raycasts to hit from within any shield once
# the ray is already inside it.

# Put a bullet image in bread crumb here
# for testing purposes. I tested ricochet
# using this.
#@export var bread_crumb : PackedScene

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
	data = dat
	damage = dat.damage
	# Point the projectile in the given direction
	global_transform = dat.gun.global_transform
	# Set velocity
	velocity = -transform.basis.z * speed
	# Randomize angle that bullet comes out. I'm cutting
	# spread in half so that a 10 degree spread is
	# 10 degrees total, not plus or minus 10 degrees.
	var spread:float = deg_to_rad(dat.spread_deg/2.0)
	# I'm not sure why .normalized() is needed here
	# and it concerns me that I either need it
	# everywhere that this sort of rotation is performed
	# or that something is going uniquely wrong
	# such that the bases are not normalized (but should be)
	transform.basis = transform.basis.rotated(transform.basis.x.normalized(), randf_range(-spread, spread))
	transform.basis = transform.basis.rotated(transform.basis.y.normalized(), randf_range(-spread, spread))
	# Set velocity, but global this time!
	velocity = -global_transform.basis.z * speed
	# 'Super powered' doubles turn rate (which is done
	# in the controller) and 10xs damage
	if dat.super_powered:
		damage *= 10.0
	# Set target for seeking munitions
	if controller:
		controller.set_data(dat)


func get_range() -> float:
	return speed * time_out


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Was previously used for testing:
	#var crumb = bread_crumb.instantiate()
	# Add to main_3d, not root, otherwise the added
	# node might not be properly cleared when
	# transitioning to a new scene.
	#Global.main_scene.main_3d.add_child(crumb)
	#crumb.transform = transform
	#crumb.transform.basis = transform.basis.rotated(transform.basis.x.normalized(), PI/2)
	#crumb.global_position = global_position
	
	# Seeker missiles and other bullets might
	# use one of a number of different controllers
	# that modify the velocity.
	if controller:
		controller.move_me(self, delta)
	# Move forward
	global_position += velocity * delta


func damage_and_die(body, collision_point=null):
	# Damage what was hit
	#https://www.youtube.com/watch?v=LuUjqHU-wBw
	if !passes_through(body) and body.is_in_group("damageable"):
		#print("dealt damage")
		body.damage(damage)
	# Make a spark at collision point
	if collision_point:
		# https://www.udemy.com/course/complete-godot-3d/learn/lecture/41088252#questions/21003762
		var spark = null
		if body.is_in_group("shield") and shieldSparks:
			spark = shieldSparks.instantiate()
		elif sparks:
			spark = sparks.instantiate()
		if spark:
			# Add to main_3d, not root, otherwise the added
			# node might not be properly cleared when
			# transitioning to a new scene.
			Global.main_scene.main_3d.add_child(spark)
			#spark.global_transform.basis.z = -area.global_transform.basis.z
			#spark.global_transform = area.global_transform
			spark.transform = transform
			#spark.rotate_y(deg_to_rad(-90))
			#spark.rotate_x(deg_to_rad(90))
			spark.global_position = collision_point
	#Delete bullets that strike a body
	Callable(queue_free).call_deferred()


# Returns true if bullet should pass through
# the body
func passes_through(body) -> bool:
	# Null instance can occur when body dies
	# from another source of damage while this
	# projectile is still trying to damage it.
	if !body:
		return true
	# In order to fire from within a shield, we need
	# to ignore immediate collisions.
	if body.is_in_group("shield") and $Timer.wait_time - $Timer.time_left <= shield_grace_period:
		return true
	return false


# Source:
# https://www.youtube.com/watch?v=8vFOOglWW3w
func stick_decal(collision_point:Vector3, collision_normal:Vector3) -> void:
	if bullet_hole_decal:
		#Stick a decal on the target or on whatever was hit
		var decal = bullet_hole_decal.instantiate()
		# Parent decal to root, otherwise there can be
		# weird scaling if attaching as a child of a scaled
		# node.
		# Add to main_3d, not root, otherwise the added
		# node might not be properly cleared when
		# transitioning to a new scene.
		Global.main_scene.main_3d.add_child(decal)
		# Position and orient the decal
		decal.global_position = collision_point
		# https://forum.godotengine.org/t/up-vector-and-direction-between-node-origin-and-target-are-aligned-look-at-failed/20575/2
		# .is_equal_approx() should be used to compare vectors
		# because of this issue:
		# https://forum.godotengine.org/t/comparing-vectors-return-false-even-theyre-same/22474/2
		# however, the solution given on that webpage
		# is not ideal.
		if collision_normal.is_equal_approx(Vector3.DOWN):
			decal.rotation_degrees.x = 90
		elif collision_normal.is_equal_approx(Vector3.UP):
			decal.rotation_degrees.x = -90
		elif !collision_normal.is_equal_approx(Vector3.ZERO):
			decal.look_at(global_position - collision_normal, Vector3(0,1,0))


# Start near miss sound upon entering a near miss Area3D
func start_near_miss_audio() -> void:
	if data.use_near_miss:
		# If it doesn't exist yet, create it
		if !near_miss_audio:
			near_miss_audio = AudioStreamPlayer3D.new()
			var audiostream = load("res://Assets/SoundEffects/whoosh_medium_001.ogg")
			near_miss_audio.set_stream(audiostream)
			add_child(near_miss_audio)
		near_miss_audio.play()

# Stop near miss sound when striking an object
func stop_near_miss_audio() -> void:
	if near_miss_audio:
		near_miss_audio.stop()


func _on_timer_timeout() -> void:
	#print('bullet timed out')
	queue_free()
