extends CanvasLayer

# This was built off of this tutorial:
# https://www.youtube.com/watch?v=m4PfHg3hmSo
# *correct* way to Load and Switch Scenes in Godot!
# by Queble https://www.youtube.com/@queblegamedevelopment4143
# And is to be used in conjunction with the scene_loader.gd
# autoload script.

signal loading_screen_ready

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	await animation_player.animation_finished
	loading_screen_ready.emit()

func _on_progress_changed(_new_value:float) -> void:
	# TODO progress bar here
	pass

func _on_load_finished() -> void:
	animation_player.play_backwards('transition')
	await animation_player.animation_finished
	queue_free()
