extends Node3D

@export var bullet: PackedScene # What sort of bullet to fire

@export var fire_rate:= 1.0 # Shots per second. Really this is bursts per second
@onready var firing_rate_timer: Timer = $FiringRateTimer # For bullet firing rate
var can_shoot: bool = true # For bullet firing rate

#True if the gun has received the signal to fire
var firing: bool = false

@onready var burst_timer: Timer = $BurstTimer
@export var burst_total:int = 1 # How many consecutive shots are fired when trigger is pulled
@export var burst_rate:float = 1.0 # Shots in a burst per second
var burst_count:int = 0 # For tracking how many shots in the burst have been fired
var can_burst: bool = true
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

# Squared range of the gun based on bullet speed and bullet duration
var range_sqd:float
# Copy of bullet speed value from the bullet itself for
# ease of communicating this info up the tree.
var bullet_speed:float

# Called when the node enters the scene tree for the first time.
func _ready():
	# Ask bullets for their range
	var b:Projectile = bullet.instantiate()
	range_sqd = b.get_range()
	range_sqd = range_sqd*range_sqd
	bullet_speed = b.speed
	b.queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if firing and can_burst:
		# Start countdown to next burst
		burst_timer.start(1.0/burst_rate)
		burst_count += 1 # Count this burst
		can_burst = false # Wait until next burst
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
		# Randomize angle that bullet comes out. I'm cutting it
		# in half so that a 10 degree spread is truly 10 degrees
		# not plus or minus 10 degrees, which is a 20 degree spread.
		var spread:float = deg_to_rad(spread_deg/2.0)
		b.rotate_x(rng.randf_range(-spread, spread))
		b.rotate_y(rng.randf_range(-spread, spread))
		b.reset_velocity()
		# Check if we're done firing this burst
		if burst_total <= burst_count:
			firing = false
			burst_count = 0 # Reset burst count
			# Reset can_burst to true so that it doesn't
			# interfere with the firing rate
			can_burst = true
		# Check if this is a bullet that should not make a
		# whiffing noise. Currently only player bullets
		# should not self-whiff
		if turn_off_near_miss:
			b.set_collision_layer_value(3, false)

# Returns true if successful. The return is useful for
# animations and sounds
func shoot(shoot_data:ShootData) -> bool:
	if can_shoot:
		can_shoot = false
		firing = true
		can_burst = true
		firing_rate_timer.start(1.0/fire_rate)
		data = shoot_data
		return true
	return false

#firing_rate_timer serves as cooldown between shots
func _on_timer_timeout():
	can_shoot = true


func _on_burst_timer_timeout() -> void:
	can_burst = true

