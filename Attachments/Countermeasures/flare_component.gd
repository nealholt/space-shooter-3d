class_name FlareComponent extends Node3D

# Fires off a flare.
# Flare is just a projectile.
# Makes flare the target of all currently incoming missiles.

@onready var cooldown_timer: Timer = $Timer
@onready var heading: Node3D = $Heading

@export var ammo:int = 50
@export var cooldown:float = 1.0

# Keep track of all the ships or whatever targeting us
var targeters:Array[Node3D]


func launch_flare(ally_team:String, data:ShootData) -> void:
	# Can't fire if out of ammo
	if ammo <= 0: return
	# Can't fire if on cooldown
	if !cooldown_timer.is_stopped(): return
	# Decrement ammo and start timer
	ammo -= 1
	cooldown_timer.start(cooldown)
	# For starters just make a basic projectile be the flare
	var flare:Projectile = BulletSpawner.new_bullet(BulletSpawner.BULLET_TYPE.MISSILE)
	Global.add_to_team_group(flare, ally_team)
	flare.set_data(data)
	
	# Shoot the projectile out the rear instead of straight ahead
	# This is hacky as fuck
	flare.global_transform = heading.global_transform
	flare.velocity = -flare.global_transform.basis.z * flare.speed
	
	# Force all missiles to target the flare
	all_missiles_target_flare(flare)


func all_missiles_target_flare(flare:Projectile) -> void:
	# Loop backwards through targeters for safe removal.
	var i:int = targeters.size()-1
	while 0 <= i:
		# Remove invalid references.
		if !is_instance_valid(targeters[i]):
			#print('removed invalid targeter')
			targeters.remove_at(i)
		# Make any missiles target the flare
		elif targeters[i] is Projectile:
			targeters[i].set_target(flare.hit_box_component)
			#print('altering projectile target')
		i -= 1


func change_targeters(is_targeting:bool, targeter:Node3D) -> void:
	# Loop backwards through targeters for safe removal.
	var i:int = targeters.size()-1
	while 0 <= i:
		# Remove invalid references.
		if !is_instance_valid(targeters[i]):
			#print('removed invalid targeter')
			targeters.remove_at(i)
		# Check for the targeter
		elif targeters[i] == targeter:
			# If already in the array, return. We already knew
			# about this targeter.
			# If targeter is in the array but is_targeting is false,
			# then remove targeter and return.
			if !is_targeting:
				#print('removed live targeter')
				targeters.remove_at(i)
			return
		i -= 1
	# Otherwise add targeter to array
	targeters.append(targeter)
	#print('added targeter')
