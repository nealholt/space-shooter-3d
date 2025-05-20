extends VisualEffect

# NOTE: The firefly particles are explicitly set up
# for the carrier size and shape. Different shape
# would be good for other ships.

# NOTE: It might be nice to scale the environment
# effects based on distance as well as angle to the
# explosion. Currently only angle is used.

# NOTE: Since the images are positioned between the
# camera and the exploding thing, not actually AT
# the exploding thing, it's possible that the explosion
# should be obscured (for instance by a large asteroid)
# but the image gets put camera-side of the asteroid.

@onready var timer:=$Timer
@onready var explosion_sprite:=$ExplosionSprite3D
@onready var ring_sprite:=$RingSprite3D
@onready var fireflies:=$FireflyParticles3D

const MAX_ANGLE := 70.0 ## Degrees. Max angle at which the world environment is modified.
const MIN_ANGLE := 0.0 ## Degrees. Max angle at which the world environment is modified.

# Currently brightness goes up to 4x
const MAX_BRIGHTNESS_FACTOR := 4.0 ## Max factor by which brightness will be scaled when the camera is staring into the explosion.
const MIN_BRIGHTNESS_FACTOR := 1.0
# Currently contrast goes up to 3x.
# Darks become darker and brights become brighter.
# Alternatively, you can drop the contrast down, which
# washes out everything to gray. I think that's less striking.
const MAX_CONTRAST_FACTOR := 3.0 ## Max factor by which contrast will be scaled when the camera is staring into the explosion.
const MIN_CONTRAST_FACTOR := 1.0
# Currently saturation drops to zero, which leaches color
# out of the world.
const MAX_SATURATION_FACTOR := 1.0 ## Max factor by which saturation will be scaled when the camera is staring into the explosion.
const MIN_SATURATION_FACTOR := 0.0

var brightness_change_duration := 0.3 ## Seconds
var contrast_change_duration := 0.4 ## Seconds
var saturation_change_duration := 1.5 ## Seconds

var explosion_alpha_duration := 2.0 ## Tween duration for changing explosion image's alpha
var explosion_alpha_target := 0.1 ## Alpha value we are tweening to

var ring_alpha_duration := 1.5 ## Tween duration for changing ring image's alpha
var ring_alpha_target := 0.3 ## Alpha value we are tweening to
var ring_scale_duration := 1.5 ## Tween duration for changing ring image's scale
var ring_scale_target := 1.6 ## Scale value we are tweening to
var ring_scale_start := 0.1 ## Scale value we are starting at

# How far flare image will be placed from the camera
var flare_distance_min_actual := 1.0
var flare_distance_max_actual := 5.0
# Camera range from explosion which will be linearly mapped
# to the above two values, the "actual" values.
# These were experimentally determined.
var flare_distance_camera_min := 350.0
var flare_distance_camera_max := 1600.0

# How far ring image will be placed from the camera
var ring_distance_min_actual := 1.0
var ring_distance_max_actual := 5.0
# Camera range from explosion which will be linearly mapped
# to the above two values, the "actual" values.
# These were experimentally determined.
var ring_distance_camera_min := 350.0
var ring_distance_camera_max := 1600.0

# bool for whether or not this effect is still animating.
var effect_is_live := false

# Reference to current camera
var camera:Camera3D

# Backing up the world environment variables so they
# can get reset back to baseline after temporarily
# modifying them.
var baseline_brightness:float
var baseline_contrast:float
var baseline_saturation:float

var max_time:float ## Max time this effect might last.


func _ready() -> void:
	# Set max_time to be the largest of all the durations
	# then add on 50% as a buffer. After this time, the
	# effect is officially finished.
	max_time = [brightness_change_duration, contrast_change_duration, saturation_change_duration, explosion_alpha_duration, ring_alpha_duration, ring_scale_duration].max()
	max_time = max_time * 1.5 # 50% buffer
	# Back up environment baseline values every time
	# the world environment gets set (usually when the
	# level is first created).
	EventsBus.environment_set.connect(backup_environment_baselines)


func backup_environment_baselines() -> void:
	# Allow us to adjust environment. I tried to do
	# this in ready, but Godot said Global.environment
	# was null.
	Global.environment.adjustment_enabled = true
	# Save baseline values. If you do this at
	# runtime rather than in _ready and another
	# instance has already started modifying
	# environment values then they could get
	# reset incorrectly. This is safer.
	baseline_brightness = Global.environment.adjustment_brightness
	baseline_contrast = Global.environment.adjustment_contrast
	baseline_saturation = Global.environment.adjustment_saturation


func play() -> void:
	# Update the camera
	camera = get_viewport().get_camera_3d()
	
	# Get distance to camera
	var cam_distance:float = global_position.distance_to(camera.global_position)
	
	# Explosion effects
	flare_explosion(cam_distance)
	ring_explosion(cam_distance)
	
	# Angle from camera to self
	var cam_angle:float = rad_to_deg(Global.get_angle_to_target(camera.global_position, global_position, -camera.global_transform.basis.z))
	# Change environment variables.
	# remap from max to min angle because lowest values should
	# occur at max and highest at min because zero means camera
	# is staring right into the explosion.
	var factor:float = clamp(remap(cam_angle, MAX_ANGLE,MIN_ANGLE, MIN_BRIGHTNESS_FACTOR,MAX_BRIGHTNESS_FACTOR), MIN_BRIGHTNESS_FACTOR, MAX_BRIGHTNESS_FACTOR)
	blink_environment('adjustment_brightness', baseline_brightness, factor, brightness_change_duration)
	factor = clamp(remap(cam_angle, MAX_ANGLE,MIN_ANGLE, MIN_CONTRAST_FACTOR,MAX_CONTRAST_FACTOR), MIN_CONTRAST_FACTOR, MAX_CONTRAST_FACTOR)
	blink_environment('adjustment_contrast', baseline_contrast, factor, contrast_change_duration)
	factor = clamp(remap(cam_angle, MAX_ANGLE,MIN_ANGLE, MAX_SATURATION_FACTOR, MIN_SATURATION_FACTOR), MIN_SATURATION_FACTOR, MAX_SATURATION_FACTOR)
	blink_environment('adjustment_saturation', baseline_saturation, factor, saturation_change_duration)
	
	fireflies.emitting = true
	effect_is_live = true
	timer.start(max_time)


func is_playing() -> bool:
	return effect_is_live


func stop() -> void:
	super()
	timer.stop()


func _on_animation_finished() -> void:
	super()
	effect_is_live = false
	fireflies.emitting = false
	explosion_sprite.visible = false
	ring_sprite.visible = false


func flare_explosion(cam_distance:float) -> void:
	# Reset sprite modulate value back to full
	explosion_sprite.modulate.a8 = 255
	# Figure out where to put sprite so it's between
	# camera and ship.
	var direction := camera.global_position.direction_to(global_position)
	# Determine how far away to place the sprite
	# based on distance of explosion from the camera.
	# These were experimentally determined
	# https://docs.godotengine.org/en/latest/classes/class_@globalscope.html#class-globalscope-method-remap
	var ideal_distance:float=clamp(remap(cam_distance, flare_distance_camera_min, flare_distance_camera_max, flare_distance_min_actual, flare_distance_max_actual), flare_distance_min_actual, flare_distance_max_actual)
	explosion_sprite.global_position = camera.global_position + direction * ideal_distance
	explosion_sprite.look_at(camera.global_position)
	# "look_at" puts the backside to the camera, so
	# rotate it another 180
	explosion_sprite.rotate_y(PI)
	# Add some random rotation.
	# I removed all the billboarding (it was both in
	# flags and under materials process) and instead
	# used look at so I could throw in this random
	# rotation. I don't know if it really matters, 
	# but that's what I did.
	#explosion_sprite.rotate_z(randf_range(-PI/4, PI/4))
	explosion_sprite.rotate_x(randf_range(-PI/2, PI/2))
	
	explosion_sprite.visible = true
	# Modulate sprite's opacity until it disappears
	var tween:Tween = create_tween()
	tween.tween_property(explosion_sprite,
		'modulate:a8',
		explosion_alpha_target, explosion_alpha_duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	# An animation player could be used to modify the
	# sprite in other ways, per this suggestion:
	# https://www.reddit.com/r/godot/comments/r4snzr/how_do_you_make_a_spotlight_have_a/


func ring_explosion(cam_distance:float) -> void:
	# Reset sprite modulate back to full
	ring_sprite.modulate.a8 = 255
	# Figure out where to put sprite so it's between
	# camera and ship.
	var direction := camera.global_position.direction_to(global_position)
	# Determine how far away to place the sprite
	# based on distance of explosion from the camera.
	# These were experimentally determined
	# https://docs.godotengine.org/en/latest/classes/class_@globalscope.html#class-globalscope-method-remap
	var ideal_distance:float=clamp(remap(cam_distance, ring_distance_camera_min, ring_distance_camera_max, ring_distance_min_actual, ring_distance_max_actual), flare_distance_min_actual, flare_distance_max_actual)
	ring_sprite.global_position = camera.global_position + direction * ideal_distance
	ring_sprite.look_at(camera.global_position)
	# "look_at" puts the backside to the camera, so
	# rotate it another 180
	ring_sprite.rotate_y(PI)
	# Add some random rotation
	ring_sprite.rotate_y(randf_range(-PI/4, PI/4))
	ring_sprite.rotate_x(randf_range(-PI/2, PI/2))
	ring_sprite.rotate_z(randf_range(-PI/2, PI/2))
	
	# Reset scale and visibility
	ring_sprite.scale = Vector3(ring_scale_start,ring_scale_start,ring_scale_start)
	ring_sprite.visible = true
	
	# Modulate sprite's scale and opacity until it disappears
	var tween:Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring_sprite, 'modulate:a8',
		ring_alpha_target, ring_alpha_duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring_sprite, 'scale',
		Vector3(ring_scale_target,ring_scale_target,ring_scale_target), ring_scale_duration)


# Tween into and out of an environment attribute
# modification.
# https://docs.godotengine.org/en/stable/classes/class_environment.html
func blink_environment(attribute:String, baseline:float, factor:=3.0, duration:=0.3) -> void:
	var tween:Tween = create_tween()
	var current = Global.environment.get(attribute)
	tween.tween_property(Global.environment,
		attribute, current*factor, duration
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	# Reset to baseline
	tween.tween_property(Global.environment,
		attribute, baseline, duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Tween easing animated:
	# https://www.reddit.com/r/godot/comments/14gt180/all_possible_tweening_transition_types_and_easing/
	# Graph visualization:
	# https://raw.githubusercontent.com/urodelagames/urodelagames.github.io/master/photos/tween_cheatsheet.png
