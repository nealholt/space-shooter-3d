extends Node

@onready var pause_layer :CanvasLayer = $".."

# Everything pause related is courtesy of this:
# https://www.youtube.com/watch?v=kn8yOGEvCo0
# Have to have a separate script unpause the game
# and change its process mode.
# This is also valuable:
# https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html
func _input(event: InputEvent) -> void:
	# Press pause to continue
	#if Input.is_action_just_pressed('pause'):
	
	# Press any key to continue
	if event is InputEventKey and event.pressed:
		
		# Don't re-process any inputs this frame,
		# otherwise pause will be reprocessed in main
		# and the game will pause again!
		get_viewport().set_input_as_handled()
		# If game was paused, unpause
		if get_tree().paused:
			get_tree().paused = false
			pause_layer.visible = false
