class_name HitBoxComponent extends Node3D

signal missile_locked # Emitted when an enemy acquires missile lock on this ship
signal missile_fired_inbound # Emitted when a missile is fired at this ship
signal is_targeted(tf:bool, targeter:Ship) # Emitted when this hitbox starts or stops being targeted

# collidable will only be set if the hit box component
# is associated with an Area3D. CharacterBody3Ds such as
# ships, will call down to the hit box component directly
@export var collidable:DamageableArea
# The hit box communicates damage to an associated health component
@export var health_component:HealthComponent
# The hit box triggers various audio visual feeback when hit
@export var got_hit_audio:AudioStreamPlayer
@export var hit_feedback:HitFeedback


func _ready() -> void:
	# Throw an error if health not found
	if !health_component:
		push_error('No HealthComponent found for HitBoxComponent. Did you forget to attach health to hitbox for the '+get_parent().name)
	# Connect to collidable's damaged signal
	if collidable:
		collidable.damaged.connect(damage)


# This function is called by the CharacterBody3D (usually a ship)
# or is called by a signal from the collidable Area3D when
# damage is taken.
func damage(dat:ShootData):
	#Global.friendly_fire_checker(dat.shooter, get_parent()) #TESTING
	health_component.health -= dat.damage
	if health_component.is_dead():
		is_targeted.emit(false, dat.shooter) # Can't be targeted if you're dead
	if hit_feedback:
		hit_feedback.hit()
	if got_hit_audio:
		got_hit_audio.play()


func add_damage_exception(s:Ship) -> void:
	if collidable:
		collidable.damage_exception = s
	else:
		push_error('Trying to add a damage exception but there is no DamageableArea. HitBox parent is ', get_parent())


# This is called when any ship targets this hitbox.
func set_targeted(value:bool, targeter:Ship) -> void:
	is_targeted.emit(value, targeter)


# Clean up function. Called when parent dies.
func remove_audio() -> void:
	if hit_feedback:
		hit_feedback.queue_free.call_deferred()
	if got_hit_audio:
		got_hit_audio.queue_free.call_deferred()


# This is used to deactivate hit sfx on NPC ships.
func turn_off_audio() -> void:
	if got_hit_audio:
		got_hit_audio.queue_free()
		got_hit_audio = null


# These are called by the missile lock group when
# targeter is seeking lock on this hitbox,
# loses lock, acquires lock, or fires a missile.
func seeking_lock(_targeter:Node3D) -> void:
	# This is actually triggered when the enemy starts
	# its countdown to missile lock, which is what I want
	missile_locked.emit()
	pass
func lost_lock(_targeter:Node3D) -> void:
	#print('lost_lock')
	pass
func lock_acquired(_targeter:Node3D) -> void:
	pass
func missile_inbound(_targeter:Node3D) -> void:
	missile_fired_inbound.emit()
	pass


# This function is only called by shields to toggle
# collidability when the shield is knocked out and
# when the shield regenerates.
func set_collisions(layer:int, b:bool) -> void:
	if collidable:
		# monitorable = false doesn't seem to do
		# anything. There are still collisions unless the
		# collision layer is set to false. I'm not sure why,
		# but for now I'll just turn off both.
		collidable.monitorable = b
		collidable.set_collision_layer_value(layer, b)
	else:
		push_error('I don\'t know of any scenario in which this should happen. I think only the Shield messes with collision activation directly. Did you forget to attach the DamageableArea to the export variable?')


func get_velocity() -> Vector3:
	var p = get_parent()
	if 'velocity' in p:
		return p.velocity
	else:
		return Vector3.ZERO


func is_dead() -> bool:
	return health_component.is_dead()


func has_collidable() -> bool:
	return is_instance_valid(collidable)

func get_collidable() -> DamageableArea:
	return collidable
