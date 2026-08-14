class_name FlareComponent extends Countermeasure

# Fires off a flare.
# Flare is just a projectile that gets targeted by
# incoming missiles. So we fire it from a backward-facing
# gun like any other projectile
@onready var gun: Gun = $Gun

func _ready() -> void:
	# Force all missiles to target whatever projectile the
	# gun fires off
	gun.fired_projectile.connect(all_missiles_target_flare)


# Since flares are projectiles, we need to know shoot data.
func activate_countermeasure(data:ShootData) -> void:
	# If you don't do this next bit then flares will fire
	# toward mouse when in first person mode for the player
	data.force_use_transform = true
	# Set the gun to be the flare gun
	data.set_gun(gun)
	# Shoot gun. This may return null if out of ammo, or still
	# on cooldown, or if it's set up incorrectly.
	data.shoot()

# Set all incoming, seeking projectiles to target the flare.
func all_missiles_target_flare(flare:Projectile) -> void:
	# Only proceed if the flare is valid
	if !is_instance_valid(flare): return
	remove_invalid_targeters()
	# Make any missiles target the flare
	for targeter:Node3D in targeters:
		if targeter is Projectile:
			targeter.set_target(flare.hit_box_component)
			#print('altering projectile target')
