extends Area3D
class_name Projectile

# Bullets and missiles and really any projectiles inherit
# from this class.

@export var rotation_speed: float = 0.0 # Used for projectiles that seek
@export var speed:float = 1000.0
@export var damage:float = 1.0
@export var time_out:float = 2.0 #seconds
var shooter #Who shot this projectile
var target # Used for projectiles that seek

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Timer.start(time_out)

func set_data(dat:ShootData) -> void:
	#Super powered doubles seeking and 10xs damage
	if dat.super_powered:
		rotation_speed *= 2.0
		damage *= 10.0
	# Point the projectile in the given direction
	global_transform = dat.transform
	# Tell the projectile who shot it
	shooter = dat.shooter
	# Give the projectile a target
	target = dat.target
	# For now, set my mask and layers to be those of the shooter
	#print()
	for i in range(1,4):
		set_collision_layer_value(i, shooter.get_collision_layer_value(i))
		set_collision_mask_value(i, shooter.get_collision_mask_value(i))
		#print("Layer %s" % shooter.get_collision_layer_value(i))
		#print("Mask %s" % shooter.get_collision_mask_value(i))
	#set_collision_mask_value(1, shooter.get_collision_mask_value(1))
	#set_collision_mask_value(2, shooter.get_collision_mask_value(2))
	#print(shooter.get_collision_mask_value(1))
	#print(shooter.get_collision_mask_value(2))
	#print()

func get_range() -> float:
	return speed * time_out

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	transform.origin -= transform.basis.z * speed * delta
	# Avoid trying to face queue freed targets
	if is_instance_valid(target):
		transform = Global.interp_face_target(self, target.global_position, rotation_speed*delta)

func damage_and_die(body):
	#print("bullet entered body")
	#https://www.youtube.com/watch?v=LuUjqHU-wBw
	if body.is_in_group("damageable"):
		#print("dealt damage")
		body.damage(damage)
		#Delete bullets that strike a body
		queue_free()

func _on_timer_timeout() -> void:
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	damage_and_die(body)

func _on_area_entered(area: Area3D) -> void:
	damage_and_die(area)
