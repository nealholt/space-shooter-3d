extends Level

@onready var carrier1:=$CarrierChassis
@onready var carrier2:=$CarrierChassis2
@onready var destroyer:=$BeamDestroyerChassis
@onready var frigate:=$FrigateChassis


func _on_timer_timeout() -> void:
	# Blow up carrier 1
	#$MassiveExplosion.play_at(carrier1.global_position)
	$MassiveExplosion.play_with_transform(carrier1.global_position, carrier1.transform)
	carrier1.queue_free()


func _on_timer_2_timeout() -> void:
	#$MassiveExplosion.stop()
	# Blow up carrier 2
	#$MassiveExplosion.play_at(carrier2.global_position)
	$MassiveExplosion.play_with_transform(carrier2.global_position, carrier2.transform)
	carrier2.queue_free()


func _on_timer_3_timeout() -> void:
	#$MassiveExplosion.stop()
	# Blow up the frigate
	#$MassiveExplosion.play_at(frigate.global_position)
	$MassiveExplosion.play_with_transform(frigate.global_position, frigate.transform)
	frigate.queue_free()


func _on_timer_4_timeout() -> void:
	#$MassiveExplosion.stop()
	# Blow up the destroyer
	#$MassiveExplosion.play_at(destroyer.global_position)
	$MassiveExplosion.play_with_transform(destroyer.global_position, destroyer.transform)
	destroyer.queue_free()


# Enable easy exit
func _input(_event: InputEvent) -> void:
	# Exit to main menu on exit, or if we're already
	# on the main menu, exit game
	if Input.is_action_just_pressed('exit'):
		get_tree().quit()
