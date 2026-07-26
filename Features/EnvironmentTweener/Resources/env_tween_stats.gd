class_name EnvTweenStats extends Resource

# All of the following defaults are set up for the Massive Explosion

# Min and max angle, relative to the camera, at which the world
# environment is modified.
@export var max_angle := 70.0 ## Degrees
var min_angle := 0.0 ## Degrees

## Distance at which the factor for world environment modification is one.
@export var unit_distance := 700.0

# Currently brightness goes up to 4x
@export var max_brightness_factor := 4.0 ## Max factor by which brightness will be scaled when the camera is staring into the explosion.
var min_brightness_factor := 1.0
# Currently contrast goes up to 3x.
# Darks become darker and brights become brighter.
# Alternatively, you can drop the contrast down, which
# washes out everything to gray. I think that's less striking.
@export var max_contrast_factor := 3.0 ## Max factor by which contrast will be scaled when the camera is staring into the explosion.
var min_contrast_factor := 1.0
# Currently saturation is only lowered, which leaches color
# out of the world.
var max_saturation_factor := 1.0
@export var min_saturation_factor := 0.0 ## Min factor by which saturation will be scaled when the camera is staring into the explosion.

@export var brightness_change_duration := 0.3 ## Seconds
@export var contrast_change_duration := 0.4 ## Seconds
@export var saturation_change_duration := 1.5 ## Seconds

# remap from max to min angle because lowest values should
# occur at max and highest at min because zero means camera
# is staring right into the explosion. (Except for saturation)
# Account for distance by dividing factor by
# dist/unit_distance for brightness and contrast but
# multiplying for saturation since it's inverted.
# More distance means less effect.
func get_factors(cam_angle:float, dist_normalized:float) -> Array[float]:
	var to_return:Array[float] = [1.0, 1.0, 1.0]
	# Brightness
	to_return[0] = remap(cam_angle, max_angle, min_angle, min_brightness_factor, max_brightness_factor)
	to_return[0] = clamp(to_return[0] / dist_normalized, min_brightness_factor, max_brightness_factor)
	# Contrast
	to_return[1] = remap(cam_angle, max_angle, min_angle, min_contrast_factor, max_contrast_factor)
	to_return[1] = clamp(to_return[1] / dist_normalized, min_contrast_factor, max_contrast_factor)
	# Saturation
	# Note that max and min saturation are intentionally and correctly
	# reversed on these next two lines. Clamp requires min to be less
	# than max, but we are remapping large angles to large values
	# (where large is the default) unlike for brightness and contrast
	# where small values are the default.
	to_return[2] = remap(cam_angle, max_angle, min_angle, max_saturation_factor, min_saturation_factor)
	to_return[2] = clamp(to_return[2] * dist_normalized, min_saturation_factor, max_saturation_factor)
	return to_return
