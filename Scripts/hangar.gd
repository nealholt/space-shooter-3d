class_name Hangar extends Node3D

# The hangar spawns ships on a timer.
# For now it spawns NPC fighters and is
# attached to the carrier.

# The hanger will spawn ships for this team
var ally_team:String

func _on_timer_timeout() -> void:
	if global_transform.basis.z.length() < 0.01:
		push_error('ERROR in hangar.gd: Vector too short. I\'m trying to suss out a different error and I thought this might be the issue.')
	# Spawn a new ship on the hangar's team, at the
	# hangar's location, facing the direction the
	# hangar's -z axis is facing.
	ShipSpawner.new_npc_fighter(ally_team, global_position, -global_transform.basis.z)
