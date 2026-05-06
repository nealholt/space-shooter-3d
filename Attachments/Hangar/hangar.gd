class_name Hangar extends Node3D

# The hangar spawns ships on a timer.
# For now it spawns NPC fighters and is
# attached to the carrier.

# The hanger will spawn ships for this team
var ally_team:String

# How many ships to spawn per flight.
@export var ships_per_flight := 3
var ships_launched := 0

func _on_timermacro_timeout() -> void:
	# Reset cound of ships launched with this flight
	ships_launched = 0
	# Launch first ship
	_on_timermicro_timeout()
	# Start timer to launch subsequent ships
	$TimerMicro.start()


func _on_timermicro_timeout() -> void:
	if global_transform.basis.z.length() < 0.01:
		push_error('ERROR in hangar.gd: Vector too short. I\'m trying to suss out a different error and I thought this might be the issue.')
	# Spawn a new ship on the hangar's team, at the
	# hangar's location, facing the direction the
	# hangar's -z axis is facing.
	ShipSpawner.new_npc_fighter(ally_team, global_position, -global_transform.basis.z)
	ships_launched += 1
	# If we're not finished with this flight, start the timer to launch another
	if ships_launched < ships_per_flight:
		$TimerMicro.start()
