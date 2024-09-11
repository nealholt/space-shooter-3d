extends Node3D
class_name Gun

# What sort of bullet to fire:
@export var bullet: PackedScene

@export var damage:float = 1.0

@export var fire_rate:= 1.0 # Shots per second
@onready var firing_rate_timer: Timer = $FiringRateTimer

# True if the gun has received command to fire
# at next possible opportunity
var firing: bool = false

# Whether gun is automatic or not. If true then
# holding the shoot button will fire this weapon
# as often as possible.
# If false, then this weapon will only fire when
# shoot is first pressed. Shoot must then be
# released and pressed again before firing.
@export var automatic:bool = true

# This variable is used so the player doesn't hear
# their own bullets whizzing past their head.
@export var turn_off_near_miss: bool = false

# Later in the code I convert spread_deg to radians
# and cut it in half so that the spread total is
# spread_deg rather than plus or minus spread_deg,
# which makes it twice as large.
@export var spread_deg:float = 0.0 # degrees

# Struct containing info about how and where to shoot
# and who the shooter is
var data:ShootData

# Squared range of the gun based on bullet speed
# and bullet duration
var range_sqd:float
# Copy of bullet speed value from the bullet itself
#  for ease of communicating this info up the tree.
var bullet_speed:float

@export var fire_sound: AudioStream
@export var reload_sound: AudioStream
# sound players to be created in _ready()
var fire_sound_player: AudioStreamPlayer3D
var reload_sound_player: AudioStreamPlayer3D

# Gun animation, for example, rotation of the gatling gun
@export var gun_animation : AnimationPlayer
@export var muzzle_flash : GPUParticles3D

# Only guns that actually use a raycast3d should
# have a ray, such as guns that fire laser guided
# munitions.
@export var ray : RayCast3D

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
	if firing:
		shoot_actual()


func shoot(shooter:Node3D, target:Node3D=null, powered_up:bool=false) -> void:
	if firing_rate_timer.is_stopped():
		# Animate 'em if you got 'em
		if gun_animation:
			gun_animation.play("gun_animation")
		if muzzle_flash:
			muzzle_flash.restart()
		if fire_sound_player:
			fire_sound_player.playing = true
		# Set up booleans for firing the gun
		# as soon as possible.
		firing = true
		restart_timer()
		setup_shoot_data(shooter,target,powered_up)


func restart_timer() -> void:
	firing_rate_timer.start(1.0/fire_rate)


func setup_shoot_data(shooter:Node3D, target:Node3D, powered_up:bool):
	data = ShootData.new()
	data.shooter = shooter
	# Fire from the position of the gun
	data.gun = self
	data.damage = damage
	data.spread_deg = spread_deg
	# Add the raycast to the shoot_data for
	# reference by laser-guided projectiles
	data.ray = ray
	data.target = target
	data.super_powered = powered_up
	data.turn_off_near_miss = turn_off_near_miss


func shoot_actual() -> void:
	# Create and fire the bullet
	var b = bullet.instantiate()
	# Add bullet to root node otherwise queue free
	# on shooter will queue free the bullet
	get_tree().get_root().add_child(b)
	# Pass the bullet the data about the shooter,
	# initial velocity, etcetera
	b.set_data(data)
	firing = false
