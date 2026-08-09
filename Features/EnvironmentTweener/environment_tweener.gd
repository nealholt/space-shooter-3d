class_name EnvironmentTweener extends Node
# This is used for tweening environment vaiables:
#    Brightness
#    Contrast
#    Saturation
# Originally, MassiveExplosion was the only thing to use this
# but I realized I wanted it for other explosions too
# and I might extend it later if the camera is staring into a
# star, stuff like that.

const ENVIRONMENTTWEENER_SCENE:PackedScene = preload("res://Features/EnvironmentTweener/environment_tweener.tscn")

# Reference to the world environment
var environment:Environment
# Backing up the world environment variables so they
# can get reset back to baseline after temporarily
# modifying them.
var baseline_brightness:float
var baseline_contrast:float
var baseline_saturation:float

# Static self reference.
# Now any script can reference the EnvironmentTweener like so:
# EnvironmentTweener.me
# BE WARNED: This will not work correctly if there is more
# than one EnvironmentTweener in a scene.
static var me:EnvironmentTweener = null


static func new_environment_tweener(my_parent:Node3D) -> EnvironmentTweener:
	var et := ENVIRONMENTTWEENER_SCENE.instantiate()
	my_parent.add_child(et)
	return et


func _ready() -> void:
	# Make this scene statically accessible
	#if me:
		#push_error('ERROR: Unique static EnvironmentTweener reference has already been set. This should only ever get set once.')
	# The above error occurs when player loses a level and
	# clicks retry. I have no idea why. I tried unloading
	# the level and then calling load level with call
	# deferred in main_scene.retry_current_level() but
	# nothing works. So, I'm just commenting it for now
	# the scene tree looks fine. It doesn't look like there's
	# actually a duplicate.
	me = self


func backup_environment_baselines(env:Environment) -> void:
	environment = env
	# Allow us to adjust environment.
	environment.adjustment_enabled = true
	# Save baseline values.
	baseline_brightness = environment.adjustment_brightness
	baseline_contrast = environment.adjustment_contrast
	baseline_saturation = environment.adjustment_saturation


# Takes position of the flash or explosion as input.
# Tweens environment variables based on camera position
# and direction relative to flash, as well as the other
# parameters above.
func play(flash_pos:Vector3, stats:EnvTweenStats) -> void:
	# Update the camera
	var camera:Camera3D = get_viewport().get_camera_3d()
	
	# Angle from camera to this explosion
	var cam_angle:float = rad_to_deg(Global.get_angle_to_target(camera.global_position, flash_pos, -camera.global_transform.basis.z))
	# Distance from camera to this explosion
	# normalized by UNIT_DISTANCE an arbitrary
	# distance at which the environment effects are
	# neither increased nor decreased by distance.
	var dist_normalized:float = flash_pos.distance_to(camera.global_position) / stats.unit_distance
	# Change environment variables.
	var factors:Array[float] = stats.get_factors(cam_angle, dist_normalized)
	blink_environment('adjustment_brightness', baseline_brightness, factors[0], stats.brightness_change_duration)
	blink_environment('adjustment_contrast', baseline_contrast, factors[1], stats.contrast_change_duration)
	blink_environment('adjustment_saturation', baseline_saturation, factors[2], stats.saturation_change_duration)


# Tween into and out of an environment attribute
# modification.
# https://docs.godotengine.org/en/stable/classes/class_environment.html
func blink_environment(attribute:String, baseline:float, factor:float, duration:float) -> void:
	# Do nothing if the factor is one or the duration is zero
	if factor == 1.0 or duration == 0.0:
		return
	# Tween the environment variable
	var tween:Tween = create_tween()
	var current:float = environment.get(attribute)
	tween.tween_property(environment,
		attribute, current*factor, duration
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	# Reset to baseline
	tween.tween_property(environment,
		attribute, baseline, duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Tween easing animated:
	# https://www.reddit.com/r/godot/comments/14gt180/all_possible_tweening_transition_types_and_easing/
	# Graph visualization:
	# https://raw.githubusercontent.com/urodelagames/urodelagames.github.io/master/photos/tween_cheatsheet.png
