class_name ShootData

var target:Node3D # Used for seeking missiles
var gun:Gun
var transform:Transform3D # For use positioning and orienting the bullet
var force_use_transform:bool = false # If false, may aim toward where player is looking.
var shooter:Node3D # Identifies shooter for kill attribution. Could be a ship or a turret
var super_powered:bool # True, for example, if a missile is quick launched
var ray:RayCast3D # Used for laser-guided bullets
var damage:float = 1.0
var bullet_speed:float
var bullet_timeout:float
var timeout_vary_percent:float
var spread:float # Bullet spread in radians
# True if the target's intercept is within an acceptable
# angle of where the gun is pointing
var aim_assist:bool = false
# Reference to the object, if any, that determines whether
# or not to use aim_assist
var aim_assist_obj:AimAssist
# This projectile should ignore collisions with anything
# in this array
var collision_exceptions :Array = []

# The following are for record keeping:
var shooter_name:String = ''
var shooter_team:String = ''
var bullet_type:String = ''
# This is the actual damage dealt, the difference in health
# caused by this damage dealer. This is set to zero in
# hit_box_component if an already dead target is hit again.
var actual_damage:float = 0.0
# This is the thing that got hit (if anything)
var thing_hit:Node3D = null
# Where the damaging hit occurred, if known
var collision_pos:Vector3
# Surface normal vector of where the damaging hit occurred, if known
var collision_surf_norm:Vector3

# Player can shoot without a valid target, so this should
# only be used for NPCs
func can_shoot() -> bool:
	return is_instance_valid(gun) and is_instance_valid(target)

func shoot() -> void:
	gun.shoot(self)

func set_shooter(_shooter:Node3D) -> void:
	shooter = _shooter
	shooter_name = _shooter.get_name()
	if 'ally_team' in _shooter:
		shooter_team = _shooter.ally_team

func set_gun(g:Gun) -> void:
	gun = g
	transform = g.global_transform
	damage = g.damage
	bullet_speed = g.bullet_speed
	bullet_timeout = g.bullet_timeout
	timeout_vary_percent = g.timeout_vary_percent
	spread = g.spread

func determine_aim_assist(simultaneous_shots:int) -> void:
	# Only use aim assist if it's set up on the shooter
	# and the target reference is valid
	# AND the gun only fires one bullet at a time.
	# Spread shot weapons should not use aim assist.
	if aim_assist_obj and simultaneous_shots == 1 and is_instance_valid(target):
		aim_assist = aim_assist_obj.use_aim_assist(self)
