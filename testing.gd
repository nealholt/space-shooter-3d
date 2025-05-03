extends Node3D

var environment:Environment

func _ready() -> void:
	# Allow us to adjust environment
	environment = $WorldEnvironment.environment
	environment.adjustment_enabled = true


func _on_timer_timeout() -> void:
	# Change environment variables
	blink_environment('adjustment_brightness')
	blink_environment('adjustment_contrast')
	blink_environment('adjustment_saturation', 0.1) # Less than 1 to briefly leach color out of the world


# Tween into and out of an environment attribute
# modification.
# https://docs.godotengine.org/en/stable/classes/class_environment.html
func blink_environment(attribute:String, factor:=3.0, duration:=0.3) -> void:
	var tween:Tween = create_tween()
	#var baseline = environment.adjustment_brightness
	var baseline = environment.get(attribute)
	tween.tween_property(environment,
		attribute,
		baseline*factor, duration) #.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	# Reset to baseline
	tween.tween_property(environment,
		attribute,
		baseline, duration) #.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Enable easy exit
func _input(_event: InputEvent) -> void:
	# Exit to main menu on exit, or if we're already
	# on the main menu, exit game
	if Input.is_action_just_pressed('exit'):
		get_tree().quit()
