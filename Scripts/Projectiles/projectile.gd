class_name Projectile extends Node3D
# Bullets and missiles and all projectiles inherit
# from this class.

@onready var timer: Timer = $Timer

@export var speed:float = 1000.0
var velocity : Vector3

# This is for guided projectiles
var controller:Controller
# These next two are for projectiles that can be shot down.
# These are NOT for the projectile hitting its target.
var health_component:HealthComponent
var hit_box_component:HitBoxComponent
# This is only for projectiles that use a ray to detect
# collisions.
var ray:RayCast3D

# Damage dealt to target
var damage:float = 1.0
# Duration before the projectile expires
@export var time_out:float = 2.0 #seconds

# Data on shooter and target:
var data:ShootData

@export var deathExplosion:VisualEffectSetting.VISUAL_EFFECT_TYPE
# Different spark effects depending on what gets hit
@export var sparks:VisualEffectSetting.VISUAL_EFFECT_TYPE
@export var shieldSparks:VisualEffectSetting.VISUAL_EFFECT_TYPE
# Bullet hole decal
@export var bullet_hole_decal:VisualEffectSetting.VISUAL_EFFECT_TYPE

# Audio to play when entering a "near miss" area.
var near_miss_audio: AudioStreamPlayer3D

# This is needed because simultaneous shots
# all reference the same shoot_data so we
# don't want to modify the shoot_data.aim_assist
# bool, otherwise only one of all the shots
# will use the aim assist
var aim_assist_unhandled:bool = true

# Time after this projectile "dies" to let it linger
# so its special effects, such as smoke trail, don't
# instantaneously disappear.
@export var wrap_up_time:float = 0.0
var wrap_up_timer:Timer


func _ready() -> void:
	# Give the bullet a default velocity.
	# Useful for testing even if the velocity
	# is updated each frame
	velocity = -global_transform.basis.z * speed
	timer.start(time_out)
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
		elif child is RayCast3D:
			ray = child


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
	apply_spread(dat)
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
	timer.start(time_out)
	# Make it so a Ship can't shoot their own bullets.
	# More often this is making a shooter not shoot down
	# their own missiles, because most projectiles don't
	# have a hit_box_component, but missiles do.
	if hit_box_component:
		hit_box_component.add_damage_exception(dat.shooter)
	# Make any ray ignore the shooter and the shooter's shield.
	# This will prevent self-hits.
	if ray and dat.shooter:
		ray.add_exception(dat.shooter)
		if dat.shooter is Ship and dat.shooter.shield:
			ray.add_exception(dat.shooter.shield.hit_box_component)


# Randomize heading of this bullet based on ShootData
func apply_spread(dat:ShootData) -> void:
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Reorient on target intercept if aim assist is
	# on, but only do so once and then turn it off.
	# I do this here, rather than in set_data
	# because the frame of delay between set_data
	# and phyics_process can make the intercept
	# outdated enough that it doesn't work.
	# IMPORTANT: spread is still applied so that
	# bullets look natural, but aim assist is still
	# valuable because it centers the spread on
	# the projected intercept position.
	if aim_assist_unhandled and data:
		# If aim assist is on and the target is valid, intercept
		# the target.
		if data.aim_assist and is_instance_valid(data.target):
			var intercept:Vector3 = Global.get_intercept(
				global_position, speed, data.target)
			look_at(intercept, Vector3.UP)
			apply_spread(data)
			velocity = -global_transform.basis.z * speed
		# Else if the shooter is the player and the player is
		# using mouse controls, and the player is in first
		# person...
		# (I added in "if Global.player" because there is a
		# rare error when there is no player, yet the first
		# three conditions here are true. I think it can occur
		# because null==null is true in Godot, so hopefully
		# this fixes it.)
		elif Global.player and data.shooter == Global.player and Global.input_man.use_mouse_and_keyboard and Global.player.camera_group.is_first_person():
			#shoot at mouse / cursor
			aim_self_at_cursor()
		# Turn off aim assist. It's been handled
		aim_assist_unhandled = false
	
	# Seeker missiles and other bullets might
	# use one of a number of different controllers
	# that modify the velocity.
	if controller:
		controller.move_me(self, delta)
	# Move forward
	global_position += velocity * delta



func aim_self_at_cursor() -> void:
	var mouse_pos:Vector2 = Global.input_man.mouse_pos
	# The following if makes the projectile head off
	# toward the mouse/cursor if the mouse is near screen
	# center, and makes the projectile head toward the
	# nearest point on the circle that limits the mouse/cursor
	# when the mouse is not near screen center.
	if !Global.player.is_mouse_near_center():
		# Find the vector toward the mouse from
		# screen center, shrink it to the proper length,
		# and add it to the screen center.
		var half_size : Vector2 = Global.input_man.current_viewport.size / 2
		# Get mouse x and y relative to screen center
		var x_rel_center = half_size.x - mouse_pos.x
		var y_rel_center = half_size.y - mouse_pos.y
		mouse_pos = Vector2(x_rel_center, y_rel_center)
		var aim_radius:float = data.shooter.get_mouse_center_radius()
		var vect_length := mouse_pos.length()
		# Shrink vector to length and subtract it off of screen center
		mouse_pos = half_size - mouse_pos*(aim_radius / vect_length)
		#print(mouse_position)
	var camera := Global.input_man.current_viewport.get_camera_3d()
	# Go to camera position + camera direction times 100000
	var go_to_point := camera.project_ray_origin(mouse_pos) + camera.project_ray_normal(mouse_pos) * 100000
	look_at(go_to_point, Vector3.UP)
	apply_spread(data)
	velocity = -global_transform.basis.z * speed


func damage_and_die(body, collision_point=null) -> void:
	# Null instance can occur when body dies
	# from another source of damage while this
	# projectile is still trying to damage it.
	if !is_instance_valid(body):
		return
	# Play feedback for player if relevant
	Global.player_feedback(body, data)
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
	wrap_up()


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
	wrap_up()


func _on_health_component_died() -> void:
	# Explode
	VfxManager.play_with_transform(deathExplosion, global_position, transform)
	wrap_up()


# This function gives certain projectiles (mostly missiles)
# an opportunity to wrap up their special effects, such as
# smoke trails, before queue_freeing the projectile.
func wrap_up() -> void:
	if wrap_up_time <= 0.0:
		Callable(queue_free).call_deferred()
		return
	# Turn off physics processes
	set_physics_process(false)
	set_process(false)
	# Tell all GPU particle children to stop emitting
	# Free RayCast3D children
	# Free HitBoxComponent children
	# Cut down the lifespan of Trail3D
	# Anything else visible should hide (Stuff like
	# the model of a torpedo)
	for child in get_children():
		if child is GPUParticles3D:
			child.one_shot = true
			child.emitting = false
		elif child is RayCast3D:
			Callable(child.queue_free).call_deferred()
		elif child is HitBoxComponent:
			Callable(child.queue_free).call_deferred()
		elif child is Trail3D:
			child._lifeSpan = child._lifeSpan/10.0
		elif child.get('visible'):
			child.hide()
	# Start up a timer and queue_free all the rest when it goes off
	wrap_up_timer = Timer.new()
	add_child(wrap_up_timer)
	wrap_up_timer.timeout.connect(queue_free)
	wrap_up_timer.start(wrap_up_time)
