extends Node3D
class_name ExplosionDamaging

@export var explosion_vfx:VisualEffectSetting.VISUAL_EFFECT_TYPE

var damage_amt:float = 1.0

# The shooter of this bullet. Could be a Ship or
# a Turret, but for now I'm declaring a Ship.
# This should be passed in so that ships can't
# destroy their own missiles.
var shooter:Ship

# Use this to delete the scene after dealing
# damage OR after two runs through _process.
var delete_me:bool = false

func _process(_delta: float) -> void:
	if !delete_me:
		VfxManager.play_with_transform(explosion_vfx, global_position, transform)
	# Damage all overlapping bodies
	for body in $Area3D.get_overlapping_bodies():
		if body.is_in_group("damageable"):
			body.damage(damage_amt, shooter)
			delete_me = true
	# Damage all overlapping areas
	for area in $Area3D.get_overlapping_areas():
		if area.is_in_group("damageable"):
			area.damage(damage_amt, shooter)
			delete_me = true
	# Wait until the end of the frame to execute queue_free
	if delete_me:
		Callable(queue_free).call_deferred()
	delete_me = true
