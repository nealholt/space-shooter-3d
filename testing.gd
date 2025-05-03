extends Node3D

@onready var world_env:=$WorldEnvironment

func _ready() -> void:
	$Timer.start()

func _on_timer_timeout() -> void:
	pass # Replace with function body.
	#world_env

func _input(_event: InputEvent) -> void:
	# Exit to main menu on exit, or if we're already
	# on the main menu, exit game
	if Input.is_action_just_pressed('exit'):
		get_tree().quit()
