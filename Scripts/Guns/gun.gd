extends Node3D
class_name Gun

# What sort of bullet to fire:
@export var bullet: PackedScene

@export var damage:float = 1.0
@export var bullet_speed:float = 1000.0
@export var bullet_timeout:float = 2.0

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
@export var use_near_miss: bool = true

# Later in the code I convert spread_deg to radians
# and cut it in half so that the spread total is
# spread_deg rather than plus or minus spread_deg,
# which makes it twice as large.
@export var spread_deg:float = 0.0 # degrees

# How many bullets to spawn simultaneously
@export var simultaneous_shots:int = 1

# Struct containing info about how and where to shoot
# and who the shooter is
var data:ShootData

# Squared range of the gun based on bullet speed
# and bullet duration
var range_sqd:float

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

# Objects to ignore collisions with. All bullets
# fired by this gun will ignore collisions with
# objects in this array.
# I could not get this to work as an Array, so now
# it's just two items explicitly.
@export var collision_exception1 : Area3D
@export var collision_exception2 : Area3D


# Called when the node enters the scene tree for the first time.
func _ready():
	# Calculate bullet range
	range_sqd = (bullet_speed*bullet_timeout)*(bullet_speed*bullet_timeout)
	# create fire audio stream
	if fire_sound:
		fire_sound_player = AudioStreamPlayer3D.new()
		fire_sound_player.stream = fire_sound
		fire_sound_player.volume_db = -10.0 #quieter
		add_child(fire_sound_player)
	# create reload audio stream
	if reload_sound:
		reload_sound_player = AudioStreamPlayer3D.new()
		reload_sound_player.stream = reload_sound
		reload_sound_player.volume_db = -20.0 #quieter
		add_child(reload_sound_player)


# Called every frame. 'delta' is the elapsed time
# since the previous frame.
func _process(_delta):
	if firing:
		shoot_actual()


func ready_to_fire() -> bool:
	return !firing and firing_rate_timer.is_stopped()


func shoot(shooter:Node3D, target:Node3D=null, powered_up:bool=false) -> void:
	if ready_to_fire():
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
	data.bullet_speed = bullet_speed
	data.bullet_timeout = bullet_timeout
	data.spread_deg = spread_deg
	# Add the raycast to the shoot_data for
	# reference by laser-guided projectiles
	data.ray = ray
	data.target = target
	data.super_powered = powered_up
	data.use_near_miss = use_near_miss
	if is_instance_valid(collision_exception1):
		data.collision_exception1 = collision_exception1
	if is_instance_valid(collision_exception2):
		data.collision_exception2 = collision_exception2


func shoot_actual() -> void:
	for i in range(simultaneous_shots):
		# Create and fire bullet(s)
		var b = bullet.instantiate()
		# Add to main_3d, not root, otherwise the added
		# node might not be properly cleared when
		# transitioning to a new scene.
		Global.main_scene.main_3d.add_child(b)
		# Pass the bullet the data about the shooter,
		# initial velocity, etcetera
		b.set_data(data)
	firing = false


# Called by weapon handler when switching to a
# different weapon
func deactivate() -> void:
	#visible = false
	set_process(false)
	if gun_animation:
		gun_animation.stop()
	# Don't stop the muzzle flash. Let it play out.
	# But... it doesn't play out, then it plays
	# when you switch back to it. That's not ideal.
	# HOWEVER, if you leave visible to true
	# (see top of this function) then it all works
	# out fine.
	#if muzzle_flash:
	#	muzzle_flash.emitting = false
	# Don't stop the reload sound. Let it play out.
	#if reload_sound_player:
	#	reload_sound_player.playing = false
	if fire_sound_player:
		fire_sound_player.playing = false
	firing = false
	if ray:
		ray.enabled = false


# Called by weapon handler when switching to
# this weapon
func activate() -> void:
	visible = true
	set_process(true)
	if ray:
		ray.enabled = true
