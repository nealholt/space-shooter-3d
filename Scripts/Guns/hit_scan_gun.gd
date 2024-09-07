extends Node3D

# The following code initially based on the hitscan
# weapon from the FPS tutorial here:
# https://www.udemy.com/course/complete-godot-3d/

@export var fire_rate := 14.0 # number of times to fire per second
@export var weapon_damage := 15
@export var muzzle_flash:GPUParticles3D
# GPU particles to spawn on point of impact:
@export var sparks:PackedScene
# Whether this weapon is semiauto or automatic:
@export var automatic:bool

@onready var cooldown_timer: Timer = $CooldownTimer
@onready var ray_cast_3d: RayCast3D = $RayCast3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if automatic:
		if Input.is_action_pressed("fire"):
			if cooldown_timer.is_stopped():
				shoot()
	else: # Semiautomatic
		if Input.is_action_just_pressed("fire"):
			if cooldown_timer.is_stopped():
				shoot()


# https://www.udemy.com/course/complete-godot-3d/learn/lecture/41088242#questions
func shoot() -> void:
	muzzle_flash.restart()
	cooldown_timer.start(1.0/fire_rate)
	# Print multiple strings with tabs inbetween
	var collider = ray_cast_3d.get_collider()
	#printt('weapon fired', collider)
	if ray_cast_3d.is_colliding():
		if collider.is_in_group("damageable"):
			#print("dealt damage")
			collider.damage(weapon_damage)
		# Spawn sparks on location of hit
		var spark = sparks.instantiate()
		add_child(spark)
		spark.global_position = ray_cast_3d.get_collision_point()
