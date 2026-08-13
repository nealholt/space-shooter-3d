class_name FlareComponent extends Countermeasure

# Fires off a flare.
# Flare is just a projectile.
# Makes flare the target of all currently incoming missiles.

@onready var cooldown_timer: Timer = $Timer
# Heading is just a Node3D turned around backwards so that
# flares come out the back.
@onready var heading: Node3D = $Heading

# Total number of flares available
@export var ammo:int = 50
# Cooldown between flare uses
@export var cooldown:float = 1.0 ## Seconds


# Since flares are projectiles, we need to know ally team
# and shoot data.
func activate_countermeasure(ally_team:String, data:ShootData) -> void:
	# Can't fire if out of ammo
	if ammo <= 0: return
	# Can't fire if on cooldown
	if !cooldown_timer.is_stopped(): return
	# Decrement ammo and start timer
	ammo -= 1
	cooldown_timer.start(cooldown)
	# For now just make a basic missile be the flare
	var flare:Projectile = BulletSpawner.new_bullet(BulletSpawner.BULLET_TYPE.MISSILE)
	# Put the flare in the world
	Global.add_to_team_group(flare, ally_team)
	# Alter the transform before setting data
	data.transform = heading.global_transform
	flare.set_data(data)
	
	# TODO TESTING delete this?
	# Why can't I delete this hacky transform setting?
	# Shoot the projectile out the rear instead of straight ahead
	# This is hacky as fuck
	flare.global_transform = heading.global_transform
	flare.velocity = -flare.global_transform.basis.z * flare.speed
	
	# Force all missiles to target the flare
	all_missiles_target_flare(flare)


func all_missiles_target_flare(flare:Projectile) -> void:
	remove_invalid_targeters()
	# Loop backwards through targeters for safe removal.
	var i:int = targeters.size()-1
	while 0 <= i:
		# Make any missiles target the flare
		if targeters[i] is Projectile:
			targeters[i].set_target(flare.hit_box_component)
			#print('altering projectile target')
		i -= 1
