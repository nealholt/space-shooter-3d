extends Node3D
class_name ExplosionDamaging

@onready var area_3d: Area3D = $Area3D

@export var explosion_vfx:VisualEffectSetting.VISUAL_EFFECT_TYPE

var shoot_data:ShootData
# Use this to delete the scene after dealing
# damage OR after two runs through _process.
var delete_me:bool = false


func set_shoot_data(_shoot_data:ShootData) -> void:
	shoot_data = _shoot_data
	shoot_data.bullet_type = 'Explosion'


func _process(_delta: float) -> void:
	if !delete_me:
		VfxManager.play_with_transform(explosion_vfx, global_position, transform)
	# Damage all overlapping bodies
	for body in area_3d.get_overlapping_bodies():
		if body.is_in_group("damageable"):
			body.damage(shoot_data)
			delete_me = true
	# Damage all overlapping areas
	for area in area_3d.get_overlapping_areas():
		if area.is_in_group("damageable"):
			area.damage(shoot_data)
			delete_me = true
	# Wait until the end of the frame to execute queue_free
	if delete_me:
		queue_free.call_deferred()
	delete_me = true
