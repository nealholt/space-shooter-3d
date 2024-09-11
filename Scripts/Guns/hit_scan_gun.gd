extends Node3D

# The following code initially based on the hitscan
# weapon from the FPS tutorial here:
# https://www.udemy.com/course/complete-godot-3d/

@export var fire_rate := 5.0 # number of times to fire per second
@export var weapon_damage := 1
@export var muzzle_flash:GPUParticles3D
# GPU particles to spawn on point of impact:
@export var sparks:PackedScene

@onready var cooldown_timer: Timer = $CooldownTimer
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var laser_mesh: MeshInstance3D = $Node/Head/LaserMesh

#True if the gun has received command to fire
var firing: bool = false

# Whether gun is automatic or not. If true then
# holding the shoot button will fire this weapon.
# If false, then this weapon will only fire when
# shoot is first pressed.
@export var automatic:bool = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if firing:
		firing = false
		if muzzle_flash:
			muzzle_flash.restart()
		cooldown_timer.start(1.0/fire_rate)
		var collider = ray_cast_3d.get_collider()
		# Print multiple strings with tabs inbetween
		#printt('weapon fired', collider)
		if ray_cast_3d.is_colliding():
			if collider.is_in_group("damageable"):
				#print("dealt damage")
				collider.damage(1)
			# Spawn sparks on location of hit
			if sparks:
				var spark = sparks.instantiate()
				add_child(spark)
				spark.global_position = ray_cast_3d.get_collision_point()
		position_laser(ray_cast_3d)


func position_laser(ray:RayCast3D) -> void:
	# The idea here is to put the Head node at
	# the position and orientation of the gun,
	# but the interleaving generic Node disconnects
	# its children from the movement of the parent
	# (Inspired by this post:
	# https://www.reddit.com/r/godot/comments/ml7bhk/how_to_make_a_child_position_independent_from/
	# )
	# I wanted this so that the laser lingers in space
	# where it was fired, rather than firing and
	# continuing to move with the ship.
	$Node/Head.global_position = global_position
	$Node/Head.global_transform = global_transform
	# Change laser mesh length and position relative to Head
	# so the laser doesn't appear to pass through what it hits
	if ray.is_colliding():
		var length = global_position.distance_to(ray_cast_3d.get_collision_point())
		laser_mesh.position.z = -length/2
		laser_mesh.mesh.set_height(length)
	else:
		# Default position and length:
		laser_mesh.position.z = -500
		laser_mesh.mesh.set_height(1000)


func shoot(_shoot_data:ShootData) -> void:
	if cooldown_timer.is_stopped():
		firing = true
		$Node/Head/LaserMesh/AnimationPlayer.play("FadeOut")
