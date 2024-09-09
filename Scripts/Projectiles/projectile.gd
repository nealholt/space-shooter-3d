extends Area3D
class_name Projectile

# Bullets and missiles and really any projectiles inherit
# from this class.

# Different spark effects depending on what gets hit
@export var sparks : PackedScene
@export var shieldSparks : PackedScene

@export var steer_force: float = 50.0 # Used for projectiles that seek
@export var speed:float = 1000.0
@export var damage:float = 1.0
@export var time_out:float = 2.0 #seconds
var shooter #Who shot this projectile
var target # Used for projectiles that seek

var velocity : Vector3
var acceleration := Vector3.ZERO #non zero probably only for missiles

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print("bullet created")
	# Give the bullet a default velocity so that you
	# can put it in scenes and let it fly into a target.
	# I first used this for testing out the shield bubble.
	velocity = -global_transform.basis.z * speed
	$Timer.start(time_out)

func set_data(dat:ShootData) -> void:
	# 'Super powered' doubles turn rate and 10xs damage
	if dat.super_powered:
		steer_force *= 2.0
		damage *= 10.0
	# Point the projectile in the given direction
	global_transform = dat.transform
	velocity = -dat.transform.basis.z * speed
	# Give the projectile a target
	target = dat.target
	# Tell the projectile who shot it
	shooter = dat.shooter


func reset_velocity() -> void:
	velocity = -global_transform.basis.z * speed


func get_range() -> float:
	return speed * time_out


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Avoid turning toward invalid targets.
	# Having a non-null target indicates that this is
	# a seeking projectile.
	if is_instance_valid(target):
		# Acceleration should be zero unless this is a seeking missile
		acceleration = seek()
		# Adjust velocity based on acceleration
		velocity += acceleration * delta
		# Face the point in local space that is our current
		# position adjusted in the direction of the new
		# velocity
		look_at(transform.origin + velocity, global_transform.basis.y)
	# Move forward
	global_position += velocity * delta


# Source:
# https://www.youtube.com/watch?v=pRYMy5uQSpo
# with a great deal of help from
# https://www.youtube.com/watch?v=cgVNu5-7f0w&ab_channel=IndieQuest
# to make it work in 3d
func seek() -> Vector3:
	# Make sure target has a velocity attribute, otherwise
	# use zero velocity.
	var targ_vel = Vector3.ZERO
	if "velocity" in target:
		targ_vel = target.velocity
	# Lead the target by getting the position where we
	# can intercept it from the current position at speed.
	var target_pos := Global.get_intercept(
			global_position,
			speed,
			target.global_position,
			targ_vel)
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
	
	# Testing
	#print($Timer.wait_time - $Timer.time_left)
	
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
