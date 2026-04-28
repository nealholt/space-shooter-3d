class_name ShootData

var target:Node3D # Used for seeking missiles
var gun:Gun # For use positioning and orienting the bullet
var shooter # Identifies shooter for kill attribution
var super_powered:bool # True, for example, if a missile is quick launched
var ray:RayCast3D # Used for laser-guided bullets
var damage:float = 1.0
var bullet_speed:float
var bullet_timeout:float
var timeout_vary_percent:float
var spread_deg:float # Bullet spread in degrees
# If aim_assist is not zero, then bullets should
# adjust to face this location, it will be the
# intercept returned by aim_assist.gd
var aim_assist:bool = false
# This projectile should ignore collisions with anything
# in this array
var collision_exceptions := Array()

# Player can shoot without a valid target, so this should
# only be used for NPCs
func can_shoot() -> bool:
	return is_instance_valid(gun) and is_instance_valid(target)

func shoot() -> void:
	gun.shoot(self)

func determine_aim_assist(simultaneous_shots:int) -> void:
	# Only use aim assist if it's set up on the shooter
	# and the target reference is valid
	# AND the gun only fires one bullet at a time.
	# Spread shot weapons should not use aim assist.
	if "aim_assist" in shooter and shooter.aim_assist and simultaneous_shots == 1 and is_instance_valid(target):
		aim_assist = shooter.aim_assist.use_aim_assist(self)
