extends Area3D
class_name Projectile

# Bullets and missiles and really any projectiles inherit
# from this class.

@export var steer_force: float = 50.0 # Used for projectiles that seek
@export var speed:float = 1000.0
@export var damage:float = 1.0
@export var time_out:float = 2.0 #seconds
var shooter #Who shot this projectile
var target # Used for projectiles that seek

var velocity := Vector3.ZERO
var acceleration := Vector3.ZERO #non zero probably only for missiles

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print("bullet created")
	$Timer.start(time_out)

func set_data(dat:ShootData) -> void:
	#Super powered doubles seeking and 10xs damage
	if dat.super_powered:
		steer_force *= 2.0
		damage *= 10.0
	# Point the projectile in the given direction
	global_transform = dat.transform
	velocity = -dat.transform.basis.z * speed
	# Give the projectile a target
	target = dat.target
	if dat.shooter:
		# Tell the projectile who shot it
		shooter = dat.shooter


func get_range() -> float:
	return speed * time_out


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	acceleration = seek()
	velocity += acceleration * delta
	look_at(transform.origin + velocity, transform.basis.y)
	global_position += velocity * delta


# Source:
# https://www.youtube.com/watch?v=pRYMy5uQSpo
# with a great deal of help from
# https://www.youtube.com/watch?v=cgVNu5-7f0w&ab_channel=IndieQuest
# to make it work in 3d
func seek() -> Vector3:
	var steer := Vector3.ZERO
	# Avoid turning toward invalid targets
	if is_instance_valid(target):
		var targ_vel = Vector3.ZERO
		if "velocity" in target:
			targ_vel = target.velocity
		var target_pos := Global.get_intercept(
				global_position,
				speed,
				target.global_position,
				targ_vel)
		var desired : Vector3 = (target_pos - global_position).normalized() * speed
		steer = (desired - velocity).normalized() * steer_force
	return steer


func damage_and_die(body):
	#https://www.youtube.com/watch?v=LuUjqHU-wBw
	if body.is_in_group("damageable"):
		#print("dealt damage")
		body.damage(damage)
	#Delete bullets that strike a body
	queue_free()

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
