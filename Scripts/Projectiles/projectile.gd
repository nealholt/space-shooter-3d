extends Node3D
class_name Projectile

# Bullets and missiles and all projectiles inherit
# from this class.

@export var speed:float = 1000.0
var velocity : Vector3

var controller:Controller
var health_component:HealthComponent
var hit_box_component:HitBoxComponent

var damage:float = 1.0
@export var time_out:float = 2.0 #seconds

# Data on shooter and target:
var data:ShootData

@export var deathExplosion:VisualEffectSetting.VISUAL_EFFECT_TYPE
# Different spark effects depending on what gets hit
@export var sparks:VisualEffectSetting.VISUAL_EFFECT_TYPE
@export var shieldSparks:VisualEffectSetting.VISUAL_EFFECT_TYPE
# Bullet hole decal
@export var bullet_hole_decal:VisualEffectSetting.VISUAL_EFFECT_TYPE

var near_miss_audio: AudioStreamPlayer3D

# This is needed because simultaneous shots
# all reference the same shoot_data so we
# don't want to modify the shoot_data.aim_assist
# bool, otherwise only one of all the shots
# will use the aim assist
var aim_assist_unhandled:bool = true

# Count elapsed "frames" this will be used
# for ignoring immediate collisions such as
# when bullets spawn within shields or near-miss
# detectors or self-collisions.
var frame_count := 0

# Put a bullet image in bread crumb here
# for testing purposes. I tested ricochet
# using this.
#@export var bread_crumb : PackedScene


func _ready() -> void:
	# Give the bullet a default velocity.
	# Useful for testing even if the velocity
	# is updated each frame
	velocity = -global_transform.basis.z * speed
	$Timer.start(time_out)
	# Search through children for various components
	# and save a reference to them.
	for child in get_children():
		if child is Controller:
			controller = child
		elif child is HealthComponent:
			health_component = child
			# Connect signals with code
			health_component.died.connect(_on_health_component_died)
		elif child is HitBoxComponent:
			hit_box_component = child


# This is called by the gun that shoots the bullet.
# The gun passes in a ShootData object that specifies
# a variety of bullet attributes.
func set_data(dat:ShootData) -> void:
	data = dat
	damage = dat.damage
	speed = dat.bullet_speed
	time_out = dat.bullet_timeout
	# Point the projectile in the direction faced
	# by the gun and give the bullet the global
	# position of the gun
	global_transform = dat.gun.global_transform
	# Randomize angle that bullet comes out. I'm cutting
	# spread in half so that a 10 degree spread is
	# 10 degrees total, not plus or minus 10 degrees.
	var spread:float = deg_to_rad(dat.spread_deg/2.0)
	# I'm not sure why .normalized() is needed here
	# and it concerns me that I either need it
	# everywhere that this sort of rotation is performed
	# or that something is going uniquely wrong
	# such that the bases are not normalized (but should be)
	transform.basis = transform.basis.rotated(transform.basis.x.normalized(), randf_range(-spread, spread))
	transform.basis = transform.basis.rotated(transform.basis.y.normalized(), randf_range(-spread, spread))
	# Set velocity
	velocity = -global_transform.basis.z * speed
	# 'Super powered' doubles turn rate (which is done
	# in the controller) and 10xs damage
	if dat.super_powered:
		damage *= 10.0
	# Set target for seeking munitions
	if controller:
		controller.set_data(dat)
	# Set / reset timer
	$Timer.start(time_out)
	# Make it so a Ship can't shoot their own bullets
	if hit_box_component:
		hit_box_component.add_damage_exception(dat.shooter)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Was previously used for testing:
	#var crumb = bread_crumb.instantiate()
	# Add to main_3d, not root, otherwise the added
	# node might not be properly cleared when
	# transitioning to a new scene.
	#Global.main_scene.main_3d.add_child(crumb)
	#crumb.transform = transform
	#crumb.transform.basis = transform.basis.rotated(transform.basis.x.normalized(), PI/2)
	#crumb.global_position = global_position
	
	# Count elapsed "frames"
	frame_count+=1
	
	# Reorient on target intercept if aim assist is
	# on, but only do so once and then turn it off.
	# I do this here, rather than in set_data
	# because the frame of delay between set_data
	# and phyics_process can make the intercept
	# outdated enough that it doesn't work.
	if aim_assist_unhandled and data and data.aim_assist and data.target and is_instance_valid(data.target):
		var intercept:Vector3 = Global.get_intercept(
			global_position, speed, data.target)
		look_at(intercept, Vector3.UP)
		velocity = -global_transform.basis.z * speed
		aim_assist_unhandled = false # Turn it off. We're done
	
	# Seeker missiles and other bullets might
	# use one of a number of different controllers
	# that modify the velocity.
	if controller:
		controller.move_me(self, delta)
	# Move forward
	global_position += velocity * delta


func damage_and_die(body, collision_point=null):
	#print()
	#print('damage_and_die called')
	#print(passes_through(body))
	#print(body.is_in_group("damageable"))
	if passes_through(body):
		return
	# Damage what was hit
	#https://www.youtube.com/watch?v=LuUjqHU-wBw
	if body.is_in_group("damageable"):
		# In rare circumstances (such as testing) there
		# won't be a shooter. We need to work around that.
		var shooter = null
		if data:
			shooter = data.shooter
		body.damage(damage, shooter)
	# Make a spark at collision point
	if collision_point:
		if body.is_in_group("shield"):
			VfxManager.play_with_transform(shieldSparks, collision_point, transform)
		else:
			VfxManager.play_with_transform(sparks, collision_point, transform)
	stop_near_miss_audio()
	VfxManager.play_with_transform(deathExplosion, global_position, transform)
	#Delete bullets that strike a body
	Callable(queue_free).call_deferred()


# Returns true if bullet should pass through
# the body
func passes_through(body) -> bool:
	#print("\nframe %d" % frame_count)
	#print(body.get_parent())
	# Null instance can occur when body dies
	# from another source of damage while this
	# projectile is still trying to damage it.
	if !body:
		return true
	# In order to fire from within a shield, we need
	# to ignore immediate collisions.
	# Why the fuck does it need to be 2?!
	# But I'm telling you, if it's 1 then the
	# turrets are blowing themselves up with
	# the area projectiles. They seem okay
	# with the rays.
	if frame_count <= 2:
		#print("\nframe %d" % frame_count)
		#print(body.get_parent())
		return true
	return false


# Start near miss sound upon entering a near miss Area3D
func start_near_miss_audio() -> void:
	# If it doesn't exist yet, create it
	if !near_miss_audio:
		near_miss_audio = AudioStreamPlayer3D.new()
		var audiostream = load("res://Assets/SoundEffects/whoosh_medium_001.ogg")
		near_miss_audio.set_stream(audiostream)
		add_child(near_miss_audio)
		near_miss_audio.play()


# Stop near miss sound when striking an object
func stop_near_miss_audio() -> void:
	if near_miss_audio:
		near_miss_audio.stop()


func _on_timer_timeout() -> void:
	#print('bullet timed out')
	queue_free()


func _on_health_component_died() -> void:
	# Explode
	VfxManager.play_with_transform(deathExplosion, global_position, transform)
	Callable(queue_free).call_deferred()
