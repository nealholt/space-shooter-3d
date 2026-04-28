class_name HitBoxComponent extends Area3D
# Inspired by this:
# https://www.youtube.com/watch?v=74y6zWZfQKk&t=184s

# Warning: All the code here is duplicated in ship.gd.
# Anything that changes here, should also change there.
# Honestly, I'm not using this as much, just for 
# shoot-down-able missiles, shields, turrets, and orbs.

# Since ships are CharacterBody3Ds and those require
# collision shapes to handle phyics of collisions,
# I'm faced with the choice of either duplicate code
# (here and in ship.gd) or duplicate collision shapes
# (as children of CharacterBody3D ships and hit box area).
# Until I resolve this, I'm going to duplicate code.

@export var health_component:HealthComponent
@export var reticle_set:TargetReticles.ReticleSet
var reticle:TargetReticles

var hit_feedback:HitFeedback

# Anyone can damage this hitbox except for
# this ship. Currently this is used to prevent
# npcs from shooting down their own missiles.
var damage_exception:Ship

# So hitboxes know what team they are on. These
# are set in team_setup.gd
var ally_team:String
var enemy_team:String


func _ready() -> void:
	# Search through children for various components
	# and save a reference to them.
	for child in get_children():
		if child is HitFeedback:
			hit_feedback = child
		elif child is TargetReticles:
			reticle = child
			reticle.set_reticle_textures(reticle_set)


func damage(amount:float, damager=null):
	# A Ship shouldn't shoot down their own missiles
	if damager and is_instance_valid(damage_exception) and damager == damage_exception:
		return
	if health_component:
		#Global.friendly_fire_checker(damager, get_parent()) #TESTING
		health_component.health -= amount
		if health_component.is_dead() and is_instance_valid(reticle):
			reticle.is_targeted = false
	if hit_feedback:
		hit_feedback.hit()


func add_damage_exception(s:Ship) -> void:
	damage_exception = s


# This is called when the player targets this hitbox
# component. However, in the future, I'd like it to
# be more flexible, so now I'm passing in the
# targeter so we can check if it's the player.
func set_targeted(targeter:Node3D, value:bool) -> void:
	if Global.player == targeter and reticle:
		#print('hit box component set targeted ',value)
		reticle.is_targeted = value
	# In the future this should also signal to the
	# object that owns this hitbox that it is
	# being targeted


# These are called by the missile lock group when
# targeter is seeking lock on this hitbox,
# loses lock, acquires lock, or fires a missile.
func seeking_lock(_targeter:Node3D) -> void:
	pass
func lost_lock(_targeter:Node3D) -> void:
	pass
func lock_acquired(_targeter:Node3D) -> void:
	pass
func missile_inbound(_targeter:Node3D) -> void:
	pass
