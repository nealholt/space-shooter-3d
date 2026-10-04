class_name LoadingScreen extends CanvasLayer

# This was built off of this tutorial:
# https://www.youtube.com/watch?v=m4PfHg3hmSo
# *correct* way to Load and Switch Scenes in Godot!
# by Queble https://www.youtube.com/@queblegamedevelopment4143
# And is to be used in conjunction with the scene_loader.gd
# autoload script.

# More info can be found here:
# https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html

# Here are some alternative tutorials I have not yet looked into:
# https://www.gotut.net/loading-screen-in-godot-4/
# https://www.youtube.com/watch?v=-renxc-EmUg
# https://www.youtube.com/watch?v=dl2rUzXJtIU

signal loading_screen_ready

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var level_description_label: Label = $CenterContainer/VBoxContainer/LevelDescriptionLabel
@onready var progress_label: Label = $CenterContainer/VBoxContainer/ProgressLabel

func _ready() -> void:
	await animation_player.animation_finished
	loading_screen_ready.emit()

func _on_progress_changed(new_value:float) -> void:
	progress_label.text = 'Loading Level: '+str(int(100*new_value))+'%'
	
	pass # progress bar could be updated here

func _on_load_finished() -> void:
	progress_label.text = 'Press any key to continue'
	# Play the fade out animation backwards to fade in
	animation_player.play_backwards('transition')
	await animation_player.animation_finished
	queue_free()
