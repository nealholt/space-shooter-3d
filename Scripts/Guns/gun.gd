extends Node3D

@export var bullet: PackedScene # What sort of bullet to fire

@export var damage:float = 1.0
# Shots per second. Really this is bursts per second
@export var fire_rate:= 1.0
# For bullet firing rate:
@onready var firing_rate_timer: Timer = $FiringRateTimer

#True if the gun has received command to fire
var firing: bool = false

@onready var burst_timer: Timer = $BurstTimer
# How many consecutive shots are fired when trigger is pulled
@export var burst_total:int = 1
# Shots in a burst per second:
@export var burst_rate:float = 1.0
# For tracking how many shots in the burst have been fired
var burst_count:int = 0
# This variable is used so the player doesn't hear its own
# bullets whizzing past its head.
@export var turn_off_near_miss: bool = false

# Later in the code I convert spread_deg to radians
# and cut it in half so that the spread total is spread_deg
# rather than plus or minus spread_deg, which makes it
# twice as large.
@export var spread_deg:float = 0.0 # degrees
var rng = RandomNumberGenerator.new() #For spreading the bullets

# Struct containing info about how and where to shoot
# and who the shooter is
var data:ShootData

# Squared range of the gun based on bullet speed
# and bullet duration
var range_sqd:float
# Copy of bullet speed value from the bullet itself for
# ease of communicating this info up the tree.
var bullet_speed:float

@export var fire_sound: AudioStream
@export var reload_sound: AudioStream
# sound players to be created in _ready()
var fire_sound_player: AudioStreamPlayer3D
var reload_sound_player: AudioStreamPlayer3D

# Gun animation, for example, rotation of the gatling gun
@export var gun_animation : AnimationPlayer
@export var muzzle_flash : GPUParticles3D

# Called when the node enters the scene tree for the first time.
func _ready():
	# Ask bullets for their range
	var b:Projectile = bullet.instantiate()
	range_sqd = b.get_range()
	range_sqd = range_sqd*range_sqd
	bullet_speed = b.speed
	b.queue_free() #Then delete this bullet
	# create fire audio stream
	fire_sound_player = AudioStreamPlayer3D.new()
	fire_sound_player.stream = fire_sound
	fire_sound_player.volume_db = -10.0 #quieter
	add_child(fire_sound_player)
	# create reload audio stream
	reload_sound_player = AudioStreamPlayer3D.new()
	reload_sound_player.stream = reload_sound
	reload_sound_player.volume_db = -20.0 #quieter
	add_child(reload_sound_player)


# Called every frame. 'delta' is the elapsed time
# since the previous frame.
func _process(_delta):
	if firing and $BurstTimer.is_stopped():
		fire_sound_player.playing = true
		# Start countdown to next burst
		burst_timer.start(1.0/burst_rate)
		burst_count += 1 # Count this burst
		# Create and fire the bullet
		var b = bullet.instantiate()
		# Add bullet to root node otherwise queue free
		# on shooter will queue free the bullet
		get_tree().get_root().add_child(b)
		# Fire from the position of the gun
		data.transform = global_transform
		# Pass the bullet the data about the shooter,
		# initial velocity, etcetera
		b.set_data(data)
		b.damage = damage
		# Randomize angle that bullet comes out. I'm cutting it
		# in half so that a 10 degree spread is truly 10 degrees
		# not plus or minus 10 degrees, which is a 20 degree spread.
		var spread:float = deg_to_rad(spread_deg/2.0)
		b.rotate_x(rng.randf_range(-spread, spread))
		b.rotate_y(rng.randf_range(-spread, spread))
		b.reset_velocity()
		# Check if we're done firing this burst
		if burst_total <= burst_count:
			fire_sound_player.playing = false
			reload_sound_player.play()
			firing = false
			burst_count = 0 # Reset burst count
			# Reset can_burst to true so that it doesn't
			# interfere with the firing rate
			$BurstTimer.stop()
		# Check if this is a bullet that should not make a
		# whiffing noise. Currently only player bullets
		# should not self-whiff
		if turn_off_near_miss:
			b.set_collision_layer_value(3, false)


func shoot(shoot_data:ShootData) -> void:
	if $FiringRateTimer.is_stopped():
		# Animate 'em if you got 'em
		if gun_animation:
			gun_animation.play("rotate")
		if muzzle_flash:
			muzzle_flash.restart()
		# Set up booleans for firing the gun
		# as soon as possible.
		firing = true
		firing_rate_timer.start(1.0/fire_rate)
		data = shoot_data
		# Add the raycast to the shoot_data for
		# reference by laser-guided projectiles
		data.ray = $RayCast3D
