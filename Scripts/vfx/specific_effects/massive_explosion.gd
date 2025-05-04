extends VisualEffect

# NOTE: It might be nice to scale the environment
# effects based on distance as well as angle to the
# explosion. Currently only angle is used.

# NOTE: The firefly particles are explicitly set up
# for the carrier size and shape. Different shape
# would be good for other ships.

@onready var timer:=$Timer
@onready var explosion_sprite:=$ExplosionSprite3D
@onready var ring_sprite:=$RingSprite3D
@onready var fireflies:=$FireflyParticles3D

var effect_is_live := false

var camera:Camera3D

var baseline_brightness:float
var baseline_contrast:float
var baseline_saturation:float


func _ready() -> void:
	# Give the environment a chance to set up.
	backup_environment_baselines.call_deferred()


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
	#print(cam_distance)
	# Explosion effects
	flare_explosion(cam_distance)
	ring_explosion(cam_distance)
	
	# Angle from camera to self
	var cam_angle:float = rad_to_deg(Global.get_angle_to_target(camera.global_position, global_position, -camera.global_transform.basis.z))
	# Change environment variables
	var factor:float = clamp(remap(cam_angle, 70.0,0.0, 1.0,3.0), 1.0, 3.0)
	blink_environment('adjustment_brightness', baseline_brightness, factor)
	blink_environment('adjustment_contrast', baseline_contrast, factor)
	# Less than 1 to briefly leach color out of the world
	factor = clamp(remap(cam_angle, 70.0,0.0, 1.0,0.0), 0.0, 1.0)
	blink_environment('adjustment_saturation', baseline_saturation, factor)
	
	fireflies.emitting = true
	effect_is_live = true
	timer.start()


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
	# Determine how far away to place the sprite.
	# Limit the value to between 1.0 and 5.0
	# based on distance from the camera between 350 and 1600.
	# These were experimentally determined
	# https://docs.godotengine.org/en/latest/classes/class_@globalscope.html#class-globalscope-method-remap
	var ideal_distance:float=clamp(remap(cam_distance, 350, 1600, 1.0, 5.0), 1.0, 5.0)
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
	explosion_sprite.rotate_z(randf_range(-PI/4, PI/4))
	
	explosion_sprite.visible = true
	# Modulate sprite's opacity until it disappears
	var tween:Tween = create_tween()
	tween.tween_property(explosion_sprite,
		'modulate:a8',
		0.1, 2.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	# An animation player could be used to modify the
	# sprite in other ways, per this suggestion:
	# https://www.reddit.com/r/godot/comments/r4snzr/how_do_you_make_a_spotlight_have_a/


func ring_explosion(cam_distance:float) -> void:
	# Reset sprite modulate and scale values back to full
	ring_sprite.modulate.a8 = 255
	ring_sprite.scale = Vector3(1.0,1.0,1.0)
	# Figure out where to put sprite so it's between
	# camera and ship.
	var direction := camera.global_position.direction_to(global_position)
	# Determine how far away to place the sprite.
	# Limit the value to between 1.0 and 5.0
	# based on distance from the camera between 350 and 1600.
	# These were experimentally determined
	# https://docs.godotengine.org/en/latest/classes/class_@globalscope.html#class-globalscope-method-remap
	var ideal_distance:float= clamp(remap(cam_distance, 350, 1600, 1.0, 5.0), 1.0, 5.0)
	ring_sprite.global_position = camera.global_position + direction * ideal_distance
	ring_sprite.look_at(camera.global_position)
	# "look_at" puts the backside to the camera, so
	# rotate it another 180
	ring_sprite.rotate_y(PI)
	# Add some random rotation
	ring_sprite.rotate_y(randf_range(-PI/4, PI/4))
	ring_sprite.rotate_x(randf_range(-PI/2, PI/2))
	ring_sprite.rotate_z(randf_range(-PI/2, PI/2))
	
	ring_sprite.scale = Vector3(0.1,0.1,0.1)
	ring_sprite.visible = true
	
	# Modulate sprite's scale and opacity until it disappears
	var tween:Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring_sprite, 'modulate:a8',
		0.3, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring_sprite, 'scale',
		Vector3(1.6, 1.6, 1.6), 1.5)


# Tween into and out of an environment attribute
# modification.
# https://docs.godotengine.org/en/stable/classes/class_environment.html
func blink_environment(attribute:String, baseline:float, factor:=3.0, duration:=0.3) -> void:
	var tween:Tween = create_tween()
	var current = Global.environment.get(attribute)
	tween.tween_property(Global.environment,
		attribute,
		current*factor, duration) #.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	# Reset to baseline
	tween.tween_property(Global.environment,
		attribute,
		baseline, duration) #.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
