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
func track_damage_data(dat:ShootData) -> void:
	var datum:DamageDatum = DamageDatum.new(dat)
	#datum.print_data() # Testing
	
	# Check back 3 in the array for consolidation and
	# if not found, add the new data and move on.
	var length:int = damage_data.size()
	if damage_data.size() < 3:
		damage_data.push_back(datum)
		return
	for i in range(length-1, length-4, -1):
		if damage_data[i].consolidate_maybe(datum):
			return
	# Couldn't consolidate so just add in new data.
	damage_data.push_back(datum)


# Display every DamageDatum in the array.
func display_data() -> void:
	print('shooter,shooter_team,bullet_type,damage_dealt,thing_hit,thing_team,friendly_fire,undamageable_hit,timed_out,count')
	for d in damage_data:
		d.print_data()
