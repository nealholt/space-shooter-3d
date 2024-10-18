extends Area3D
class_name HitBoxComponent
# Inspired by this:
# https://www.youtube.com/watch?v=74y6zWZfQKk&t=184s

@export var health_component:HealthComponent
@export var hit_feedback:HitFeedback


func damage(amount:int):
	if health_component:
		health_component.health -= amount
	if hit_feedback:
		hit_feedback.hit()


# This is called when the player targets this hitbox
# component. However, in the future, I'd like it to
# be more flexible, so now I'm passing in the
# targeter so we can check if it's the player.
func set_targeted(targeter:Node3D, value:bool) -> void:
	if Global.player == targeter:
		$TargetReticles.is_targeted = value
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
