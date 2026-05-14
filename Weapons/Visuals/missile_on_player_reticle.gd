class_name MissileOnPlayerReticle extends Node

# This is a specific little scene that gets spawned by
# projectiles that 
# 1 have a controller
# 2 have a hitbox
# 3 are targeted on the player
# Then this scene modifies the hitbox reticle based on
# distance of the projectile to the player.

# It may seem odd to do it like this, but otherwise this
# very niche code is cluttering up some other scene.
# I think this is a very Single-Responsibility-Principle
# way of doing things.

const MISSILE_ON_PLAYER_SCENE:PackedScene = preload('res://Weapons/Visuals/missile_on_player_reticle.tscn')

# References to reticle and projectile
var reticle:TargetReticles
var projectile:Projectile

# These distances determine how to modify the
# reticle based on projectile distance to target.
const far_sqd := 500.0 * 500.0 # Squared for efficiency
const close_sqd := 250.0 * 250.0 # Squared for efficiency


static func new_missile_on_player(proj:Projectile, ret:TargetReticles) -> void:
	var mops := MISSILE_ON_PLAYER_SCENE.instantiate()
	proj.add_child(mops)
	mops.projectile = proj
	mops.reticle = ret
	mops.reticle.always_show = true
	mops.reticle.set_target_text.call_deferred('Missile')


func _process(_delta: float) -> void:
	# Change reticle color and size based on distance of projectile to target
	var dist:float = projectile.global_position.distance_squared_to(Global.player.global_position)
	#print(round(dist))
	if dist < close_sqd: # close
		reticle.set_color(Color.RED)
		reticle.set_reticle_scale(1.5) # 50% larger reticle
	elif dist < far_sqd: # medium
		reticle.set_color(Color.ORANGE)
		reticle.set_reticle_scale(1.3) # 30% larger reticle
	else: # far
		reticle.set_color(Color.CYAN)
		# Standard scale
