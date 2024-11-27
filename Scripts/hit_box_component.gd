extends Area3D
class_name HitBoxComponent
# Inspired by this:
# https://www.youtube.com/watch?v=74y6zWZfQKk&t=184s

# Warning: All the code here is duplicated in ship.gd.
# Anything that changes here, should also change there.
# Honestly, I'm not using this as much, just for 
# shoot-down-able missiles and for shields (and orbs).

# Since ships are CharacterBody3Ds and those require
# collision shapes to handle phyics of collisions,
# I'm faced with the choice of either duplicate code
# (here and in ship.gd) or duplicate collision shapes
# (as children of CharacterBody3D ships and hit box area).
# Until I resolve this, I'm going to duplicate code.

@export var health_component:HealthComponent

# This will be populated probably only for the player
var got_hit_audio:AudioStreamPlayer
# I'll need some other system if I want different
# audio cues for taking damage or whatever.

var hit_feedback:HitFeedback

# Anyone can damage this hitbox except for
# this ship. Currently this is used to prevent
# npcs from shooting down their own missiles.
var damage_exception:Ship

var reticle:TargetReticles

func _ready() -> void:
	# Search through children for various components
	# and save a reference to them.
	for child in get_children():
		if child is AudioStreamPlayer:
			got_hit_audio = child
		elif child is HitFeedback:
			hit_feedback = child
		elif child is TargetReticles:
			reticle = child


func damage(amount:float, damager=null):
	# A Ship shouldn't shoot down their own missiles
	if damager and is_instance_valid(damage_exception) and damager == damage_exception:
		return
	if health_component:
		health_component.health -= amount
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


# Of the following, currently only _on_body_entered
# is triggering and only when the hitbox crashes
# into a body like the side of the capital ship.
# This is fine for now, but if you want more audio
# on the hitbox side, you'll also need to adjust
# the collision bitmask.
func _on_area_entered(_area: Area3D) -> void:
	if got_hit_audio:
		got_hit_audio.play()
func _on_body_entered(_body: Node3D) -> void:
	if got_hit_audio:
		got_hit_audio.play()
