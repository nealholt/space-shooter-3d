extends VisualEffect

# NOTE: The firefly particles are explicitly set up
# for the carrier size and shape. Different shape
# would be good for other ships.

# I made the ring sprite "Double Sided" under Flags and
# also under Geometry, Material Override, Transparency,
# set Cull Mode to Disabled
# This lets me add in random rotations, but it's possible
# that the sprites will be viewed edge-on and be invisible.
# To prevent this from happening to the Explosion Sprite
# (aka the "flare") I enabled Billboard under Geometry,
# Material Override, Billboard. This however, seems to make
# rotation have no effect.
# NOTE: I think I could just make the flare a 2D sprite
# and then I could rotate it to my heart's content. I would
# simply scale it up or down to fake it being distant.

# Way too late into this, I realized it doesn't work
# if the camera is moving. Both the ring and flare are
# small 2D images put right in front of the camera. Even
# a small movement and the camera is past them or through
# them. They need to maintain their position to simulate
# being further out in space. They need to update based
# on the camera for their entire duration. Same principle
# as reticles.
# Now the process function is turned on when the effect is
# active and keeps the explosion sprites positioned
# relative to the camera.

@onready var timer:=$Timer
@onready var ring_sprite:=$RingSprite3D
@onready var flare_explosion: GPUParticles3D = $FlareExplosion

var explosion_alpha_duration := 2.0 ## Tween duration for changing explosion image's alpha

var ring_alpha_duration := 1.5 ## Tween duration for changing ring image's alpha
var ring_alpha_target := 0.3 ## Alpha value we are tweening to
var ring_scale_duration := 1.5 ## Tween duration for changing ring image's scale
var ring_scale_target := 1.6 ## Scale value we are tweening to
var ring_scale_start := 0.1 ## Scale value we are starting at

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

var max_time:float ## Max time this effect might last.


func _ready() -> void:
	# Set the particle's lifetime to be consistent with
	# other alpha effects.
	flare_explosion.lifetime = explosion_alpha_duration
	# Set max_time to be the largest of all the durations
	# then add on 50% as a buffer. After this time, the
	# effect is officially finished.
	# However, moving responsibilities out into EnvironmentTweener
	# means that this number might not be accurate!
	max_time = [explosion_alpha_duration, ring_alpha_duration, ring_scale_duration].max()
	max_time = max_time * 1.5 # 50% buffer
	# Default process function to off
	set_process(false)


# Continually update sprite positions as the camera moves
# for the duration of the explosion effect.
func _process(_delta: float) -> void:
	# Ray cast from explosion source to camera to see
	# whether the sprites should be visible or not.
	# Ignore collisions with the player.
	var obscured:bool = !RayOnDemand.me.line_is_clear(global_position, camera.global_position, Ship.player)
	# Show or hide sprites
	ring_sprite.visible = !obscured
	# No need for the following if the sprites are invisible
	if obscured:
		return
	# Figure out where to put sprite so it's between
	# camera and ship.
	var direction := camera.global_position.direction_to(global_position)
	# Get distance to the camera
	var cam_distance:float = global_position.distance_to(camera.global_position)
	# Determine how far away to place the sprite
	# based on distance of explosion from the camera.
	# These were experimentally determined
	# https://docs.godotengine.org/en/latest/classes/class_@globalscope.html#class-globalscope-method-remap
	var ideal_distance:float=clamp(remap(cam_distance, ring_distance_camera_min, ring_distance_camera_max, ring_distance_min_actual, ring_distance_max_actual), ring_distance_min_actual, ring_distance_max_actual)
	ring_sprite.global_position = camera.global_position + direction * ideal_distance


func play() -> void:
	# play activates the animation player and modifies the
	# world environment variables.
	super.play()
	# Update the camera
	camera = get_viewport().get_camera_3d()
	
	# Initiate explosion effect
	ring_explosion()
	
	# Note that the effect is live and start timer
	effect_is_live = true
	timer.start(max_time)
	
	# Turn on process function to keep the images in the
	# correct location on the screen
	set_process(true)


func is_playing() -> bool:
	return effect_is_live


func stop() -> void:
	_on_animation_finished()
	timer.stop()


func _on_animation_finished(anim_name:='') -> void:
	super(anim_name)
	effect_is_live = false
	ring_sprite.visible = false
	set_process(false) # Turn off process function


func ring_explosion() -> void:
	# Reset sprite modulate back to full
	ring_sprite.modulate.a8 = 255
	# Add some random rotation
	ring_sprite.rotate_y(randf_range(-PI/4, PI/4))
	ring_sprite.rotate_x(randf_range(-PI/2, PI/2))
	ring_sprite.rotate_z(randf_range(-PI/2, PI/2))
	
	# Reset scale
	ring_sprite.scale = Vector3(ring_scale_start,ring_scale_start,ring_scale_start)
	
	# Modulate sprite's scale and opacity until it disappears
	var tween:Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring_sprite, 'modulate:a8',
		ring_alpha_target, ring_alpha_duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring_sprite, 'scale',
		Vector3(ring_scale_target,ring_scale_target,ring_scale_target), ring_scale_duration)
