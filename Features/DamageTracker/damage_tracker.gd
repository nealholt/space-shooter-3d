class_name DamageTracker extends Node

const DAMAGE_TRACKER_SCENE:PackedScene = preload("res://Features/DamageTracker/damage_tracker.tscn")


var damage_data:Array[DamageDatum]


static func new_damage_tracker(my_parent:Node3D) -> DamageTracker:
	var dt := DAMAGE_TRACKER_SCENE.instantiate()
	my_parent.add_child(dt)
	return dt


func _ready() -> void:
	# Connect to signal
	EventsBus.register_damage.connect(track_damage_data)


# This function is called when damage is dealt or when
# a projectile dies without dealing damage.
# Add a DamageDatum to the array or consolidate with
# a recent DamageDatum already in the array.
func track_damage_data(dat:ShootData):
	var datum:DamageDatum = DamageDatum.new(dat)
	datum.print_data()
	# Check back 3 in the array for consolidation and
	# if not found, move on
	var length:int = damage_data.size()
	if damage_data.size() < 3:
		return
	for i in range(length-1, -1, length-4):
		if damage_data[i].consolidate_maybe(datum):
			return
	# Couldn't consolidate so just add in new data.
	damage_data.push_back(datum)
	
	
	#if dat.actual_damage == 0.0:
		#if dat.thing_hit:
			#print('Un-damageable thing hit')
		#else:
			#print('Projectile timed out')
	#else:
		#if 'ally_team' in dat.thing_hit and 'ally_team' in dat.shooter:
			#if dat.thing_hit.ally_team == dat.shooter.ally_team:
				#print('Friendly fire')
			#else:
				#print(dat.actual_damage, ' dealt to enemy ', dat.thing_hit.get_name(), ' by ', dat.shooter.get_name())
		#else:
			#print(dat.actual_damage, ' dealt to ', dat.thing_hit.get_name())


# Display every DamageDatum in the array.
func display_data() -> void:
	for d in damage_data:
		d.print_data()
