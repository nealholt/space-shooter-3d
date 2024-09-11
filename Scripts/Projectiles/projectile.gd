extends Area3D
class_name Projectile

# Bullets and missiles and really any projectiles inherit
# from this class.

# Different spark effects depending on what gets hit
@export var sparks : PackedScene
@export var shieldSparks : PackedScene

@export var steer_force: float = 50.0 # Used for projectiles that seek
@export var speed:float = 1000.0
var damage:float
@export var time_out:float = 2.0 #seconds
@export var laser_guided:bool = false
var ray:RayCast3D # For use by laser-guided projectiles
var shooter #Who shot this projectile
var target # Used for projectiles that seek

var velocity : Vector3
var acceleration := Vector3.ZERO #non zero probably only for missiles

# If set to true, just look at target and move toward
# it. Don't try to emulate physics at all.
@export var use_simple_seek:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print("bullet created")
	# Give the bullet a default velocity so that you
	# can put it in scenes and let it fly into a target.
	# I first used this for testing out the shield bubble.
	velocity = -global_transform.basis.z * speed
	$Timer.start(time_out)

func set_data(dat:ShootData) -> void:
	damage = dat.damage
	# 'Super powered' doubles turn rate and 10xs damage
	if dat.super_powered:
		steer_force *= 2.0
		damage *= 10.0
	# Point the projectile in the given direction
	global_transform = dat.transform
	velocity = -dat.transform.basis.z * speed
	# Randomize angle that bullet comes out. I'm cutting it
	# in half so that a 10 degree spread is truly 10 degrees
	# not plus or minus 10 degrees, which is a 20 degree spread.
	var spread:float = deg_to_rad(dat.spread_deg/2.0)
	rotate_x(randf_range(-spread, spread))
	rotate_y(randf_range(-spread, spread))
	# Give the projectile a target
	target = dat.target
	# Tell the projectile who shot it
	shooter = dat.shooter
	# Keep reference to targeting laser
	if laser_guided:
		ray = dat.ray
		# error checking
		if ray == null:
			printerr('All guns that fire laser guided projectiles, should have an attached RayCast3D')
	# Check if this is a bullet that should not make a
	# whiffing noise. Currently only player bullets
	# should not self-whiff
	if dat.turn_off_near_miss:
		set_collision_layer_value(3, false)


func reset_velocity() -> void:
	velocity = -global_transform.basis.z * speed


func get_range() -> float:
	return speed * time_out


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if use_simple_seek:
		simple_seek()
	else:
		physics_seek(delta)
	# Move forward
	global_position += velocity * delta


func simple_seek() -> void:
	# Seek target using look_at and constant speed.
	# Change direction on a dime. No vector addition
	# or physics.
	var target_pos := get_target_pos()
	look_at(target_pos, Vector3.UP)
	velocity = -transform.basis.z * speed


func physics_seek(delta:float) -> void:
	# Seek target using acceleration and vector
	# addition to make it feel "physics-y"
	
	# Avoid turning toward invalid targets.
	# Having a non-null target indicates that this is
	# a seeking projectile.
	if laser_guided or is_instance_valid(target):
		# Acceleration should be zero unless this is a seeking missile
		acceleration = get_velocity_adjustment()
		# Adjust velocity based on acceleration
		velocity += acceleration * delta
		# Face the point in local space that is our current
		# position adjusted in the direction of the new
		# velocity
		look_at(transform.origin + velocity, global_transform.basis.y)


# Returns target position or, if able, intercept
func get_target_pos() -> Vector3:
	# Update target if laser guided
	if laser_guided:
		# Get colliding object
		target = ray.get_collider()
		# If there is not colliding object
		# return the endpoint of the ray
		if target == null:
			#return ray.global_position+ray.global_transform.basis.z * ray.target_position.z
			return global_position+ray.global_transform.basis.z * ray.target_position.z
	# Check if there is a target, otherwise return origin
	if !is_instance_valid(target):
		return Vector3.ZERO
	else: # Calculate and return target intercept
		# Make sure target has a velocity attribute, otherwise
		# use zero velocity.
		var targ_vel = Vector3.ZERO
		if "velocity" in target:
			targ_vel = target.velocity
		# Lead the target by getting the position where we
		# can intercept it from the current position at speed.
		return Global.get_intercept(
				global_position,
				speed,
				target.global_position,
				targ_vel)


# Source:
# https://www.youtube.com/watch?v=pRYMy5uQSpo
# with a great deal of help from
# https://www.youtube.com/watch?v=cgVNu5-7f0w&ab_channel=IndieQuest
# to make it work in 3d
func get_velocity_adjustment() -> Vector3:
	var target_pos := get_target_pos()
	# Calculate the desired velocity, normalized and then
	# multiplied by speed.
	var desired : Vector3 = (target_pos - global_position).normalized() * speed
	# Return an adjustment to velocity based on the steer force.
	return (desired - velocity).normalized() * steer_force


func damage_and_die(body):
	# In order to fire from within a shield, we need
	# to ignore immediate collisions. So if any
	# bullet collides with another object in the first
	# 2/100ths of a second AND that body is a shield,
	# then ignore that collision.
	# 2/100ths was found through testing to be a good
	# cut off.
	if $Timer.wait_time - $Timer.time_left <= 0.02 and body.get_groups().has("shield"):
		return
	
	#https://www.youtube.com/watch?v=LuUjqHU-wBw
	if body.is_in_group("damageable"):
		#print("dealt damage")
		body.damage(damage)
	
	# Make a spark
	# https://www.udemy.com/course/complete-godot-3d/learn/lecture/41088252#questions/21003762
	var spark = null
	if body.is_in_group("shield"):
		spark = shieldSparks.instantiate()
	else:
		spark = sparks.instantiate()
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

func _on_body_entered(body: Node3D) -> void:
	#print('bullet entered a body')
	damage_and_die(body)

func _on_area_entered(area: Area3D) -> void:
	#print('bullet entered an area')
	#print(area.get_parent())
	damage_and_die(area)
