extends Node3D

# The following code initially based on the hitscan
# weapon from the FPS tutorial here:
# https://www.udemy.com/course/complete-godot-3d/

@export var fire_rate := 14.0 # number of times to fire per second
@export var weapon_damage := 15
@export var muzzle_flash:GPUParticles3D
# GPU particles to spawn on point of impact:
@export var sparks:PackedScene

@onready var cooldown_timer: Timer = $CooldownTimer
@onready var ray_cast_3d: RayCast3D = $RayCast3D

#True if the gun has received command to fire
var firing: bool = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if firing:
		firing = false
		if muzzle_flash:
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
			if sparks:
				var spark = sparks.instantiate()
				add_child(spark)
				spark.global_position = ray_cast_3d.get_collision_point()


# https://www.udemy.com/course/complete-godot-3d/learn/lecture/41088242#questions
# Returns true if successful. The return is useful for
# animations and sounds
func shoot(_shoot_data:ShootData) -> void:
	if cooldown_timer.is_stopped():
		firing = true
		$LaserMesh.visible = true
		$LaserVisualTimer.start()
		#data = shoot_data

func _on_laser_visual_timer_timeout() -> void:
	$LaserMesh.visible = false
