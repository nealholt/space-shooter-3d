extends Node3D

# NOTE: It might be nice to scale the environment
# effects based on distance as well as angle to the
# explosion. Currently only angle is used.

# NOTE: The firefly particles are explicitly set up
# for the carrier size and shape. Different shape
# would be good for other ships.

@onready var ship:=$CarrierChassis
@onready var explosion_sprite:=$ExplosionSprite3D
@onready var ring_sprite:=$RingSprite3D
@onready var fireflies:=$FireflyParticles3D

var camera:Camera3D
var environment:Environment

var baseline_brightness:float
var baseline_contrast:float
var baseline_saturation:float

func _ready() -> void:
	# Allow us to adjust environment
	environment = $WorldEnvironment.environment
	environment.adjustment_enabled = true
	# Save baseline values. If you do this at
	# runtime rather than in _ready and another
	# instance has already started modifying
	# environment values then they could get
	# reset incorrectly. This is safer.
	baseline_brightness = environment.adjustment_brightness
	baseline_contrast = environment.adjustment_contrast
	baseline_saturation = environment.adjustment_saturation


func _on_timer_timeout() -> void:
	# Get the camera
	camera = get_viewport().get_camera_3d()
	
	# Get distance to camera
	var cam_distance:float = ship.global_position.distance_to(camera.global_position)
	#print(cam_distance)
	# Explosion effects
	flare_explosion(cam_distance)
	ring_explosion(cam_distance)
	
	# Angle from camera to ship
	var cam_angle:float = 180 - rad_to_deg(camera.transform.basis.z.angle_to(ship.global_position))
	# Change environment variables
	var factor:float = clamp(remap(cam_angle, 70.0,0.0, 1.0,3.0), 1.0, 3.0)
	blink_environment('adjustment_brightness', baseline_brightness, factor)
	blink_environment('adjustment_contrast', baseline_contrast, factor)
	# Less than 1 to briefly leach color out of the world
	factor = clamp(remap(cam_angle, 70.0,0.0, 1.0,0.0), 0.0, 1.0)
	blink_environment('adjustment_saturation', baseline_saturation, factor)
	
	ship.queue_free()
	
	fireflies.global_position = ship.global_position
	fireflies.emitting = true


func flare_explosion(cam_distance:float) -> void:
	# Figure out where to put sprite so it's between
	# camera and ship.
	var direction := camera.global_position.direction_to(ship.global_position)
	# Determine how far away to place the sprite.
	# Limit the value to between 1.0 and 5.0
	# based on distance from the camera between 350 and 1600.
	# These were experimentally determined
	# https://docs.godotengine.org/en/latest/classes/class_@globalscope.html#class-globalscope-method-remap
	var ideal_distance:float=clamp(remap(cam_distance, 350, 1600, 1.0, 5.0), 1.0, 5.0)
	explosion_sprite.global_position = camera.global_position + direction * ideal_distance
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
	# Figure out where to put sprite so it's between
	# camera and ship.
	var direction := camera.global_position.direction_to(ship.global_position)
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
	var current = environment.get(attribute)
	tween.tween_property(environment,
		attribute,
		current*factor, duration) #.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
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
