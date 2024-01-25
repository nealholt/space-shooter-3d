extends StaticBody3D

signal destroyed

# Sound to be played on death. Self-freeing.
@export var pop_player: PackedScene

const MAX_COORD: int = 200

func position_randomly():
	#Spawn orbs in random location:
	#https://godotengine.org/qa/86921/random-spawning
	var coord_range = Vector2(-MAX_COORD, MAX_COORD)

	var random_x = randi() % int(coord_range[1]- coord_range[0]) + 1 + coord_range[0]
	var random_y =  randi() % int(coord_range[1]) + 1 #Minimum, is zero to not go below ground
	var random_z =  randi() % int(coord_range[1]- coord_range[0]) + 1 + coord_range[0]

	global_position = Vector3(random_x, random_y, random_z)


func _on_health_component_died() -> void:
	destroyed.emit()
	# Create self-freeing audio to play pop sound
	var on_death_sound = pop_player.instantiate()
	get_tree().get_root().add_child(on_death_sound)
	on_death_sound.play_then_delete(global_position)
	# Wait until the end of the frame to execute queue_free
	Callable(queue_free).call_deferred()
