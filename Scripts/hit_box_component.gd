extends Area3D
class_name HitBoxComponent
# Inspired by this:
# https://www.youtube.com/watch?v=74y6zWZfQKk&t=184s

@export var health_component:HealthComponent
@export var hit_feedback:HitFeedback

# This will be populated probably only for the player
var got_hit_audio:AudioStreamPlayer
# I'll need some other system if I want different
# audio cues for taking damage or whatever.


func _ready() -> void:
	# Search through children for various components
	# and save a reference to them.
	for child in get_children():
		if child is AudioStreamPlayer:
			got_hit_audio = child


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
