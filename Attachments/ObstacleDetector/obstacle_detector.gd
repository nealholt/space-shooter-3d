class_name ObstacleDetector extends Node
# Detect imminent collisions and provide information
# about how to avoid them

@onready var above := $RayAbove
@onready var ahead := $RayAhead
@onready var below := $RayBelow

var obstacle_ahead

func get_blocked_above() -> bool:
	above.force_raycast_update()
	return above.is_colliding()

func get_blocked_ahead() -> bool:
	ahead.force_raycast_update()
	var result:bool = ahead.is_colliding()
	if result:
		obstacle_ahead = ahead.get_collider()
	else:
		obstacle_ahead = null
	return result

func get_blocked_below() -> bool:
	below.force_raycast_update()
	return below.is_colliding()

func get_obstacle_ahead():
	return obstacle_ahead
