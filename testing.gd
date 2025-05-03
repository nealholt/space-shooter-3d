extends Level

@onready var ship:=$CarrierChassis


func _on_timer_timeout() -> void:
	
	#$MassiveExplosion.play_at(ship.global_position)
	$MassiveExplosion.play_with_transform(ship.global_position, ship.transform)
	
	ship.queue_free()


# Enable easy exit
func _input(_event: InputEvent) -> void:
	# Exit to main menu on exit, or if we're already
	# on the main menu, exit game
	if Input.is_action_just_pressed('exit'):
		get_tree().quit()
