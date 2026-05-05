extends Node

@onready var pause_layer := $".."

# Everything pause related is courtesy of this:
# https://www.youtube.com/watch?v=kn8yOGEvCo0
# Have to have a separate script unpause the game
# and change its process mode.
# This is also valuable:
# https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed('pause'):
		# Don't re-process any inputs this frame,
		# otherwise pause will be reprocessed in main
		# and the game will pause again!
		get_viewport().set_input_as_handled()
		if get_tree().paused:
			get_tree().paused = false
			pause_layer.visible = false
