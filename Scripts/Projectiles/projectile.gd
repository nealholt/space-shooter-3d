class_name Projectile extends Node3D
# Projectiles includes bullets and missiles and laser bolts

# You can add a Raycast3D or an Area3D as a child of
# this node and either one will automatically be used
# to detect if the bullet hit a target.

@onready var timer: Timer = $Timer

@export var speed:float = 1000.0
var velocity : Vector3

# This is for guided projectiles
var controller:Controller
# These next two are for projectiles that can be shot
# down, such as missiles.
# These are NOT for the projectile hitting its target.
var health_component:HealthComponent
var hit_box_component:HitBoxComponent
# This is only for projectiles that use a ray to
# detect collisions.
var ray:RayCastForProjectiles

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

# Time after this projectile "dies" to let it linger
# so its special effects, such as smoke trail, don't
# instantaneously disappear.
@export var wrap_up_time:float = 0.0
var wrap_up_timer:Timer

@export var does_ricochet:bool = false

# Flag for whether this projectile automatically finds a target
@export var autotarget:bool = false
# Constant roll looks pretty on projectiles with contrails.
@export var roll_amount:float = 0.0
# I thought that a little pitch might
# cause a corkscrew pattern, but it doesn't
# seem to work.
#@export var pitch_amount:float = 10.0

# Only set this if a damage-dealing explosion
# should go off when the bullet hits something.
@export var damaging_explosion:PackedScene


# Use this for timed fuse explosives, explosives go
# off when the bullet times out. If this is true
# then damaging_explosion also needs to be set
@export var explode_on_timeout:bool = false
# Add a random amount in the range of
# plus or minus this percent of bullet timeout
# on the explosion timer for variety. This only
# has an effect if explode_on_timeout is true.
@export var target_range_plus_minus:float = 0.1


func _ready() -> void:
	# Give the bullet a default velocity.
	# Useful for testing even if the velocity
	# is updated each frame
	velocity = -global_transform.basis.z * speed
	timer.start(time_out)
	# Search through children for various components
	# and save a reference to them.
	for child in get_children():
		if child is Area3D:
			# Connect to area and body entered signals
			child.area_entered.connect(_on_area_entered)
			child.body_entered.connect(_on_body_entered)
		elif child is Controller:
			controller = child
		elif child is HealthComponent:
			health_component = child
			# Connect signals with code
			health_component.died.connect(_on_health_component_died)
		elif child is HitBoxComponent:
			hit_box_component = child
		elif child is RayCastForProjectiles:
			ray = child
			ray.does_ricochet = does_ricochet
	# Error check
	if explode_on_timeout and !damaging_explosion:
		push_error('If explode_on_timeout is true then a damaging_explosion should be set.')


# This is called by the gun that shoots the bullet.
# The gun passes in a ShootData object that specifies
# a variety of bullet attributes.
func set_data(dat:ShootData) -> void:
	data = dat
	speed = dat.bullet_speed
	time_out = dat.bullet_timeout
	# Position projectile, but defer aiming.
	# ...I had an old comment saying that the deferred
	# was important... I'm not sure why and I don't
	# feel like removing it and testing that right now.
	global_transform = dat.gun.global_transform
	aim_self.call_deferred()
	# 'Super powered' doubles turn rate (which is done
	# in the controller) and 10xs damage
	if dat.super_powered:
		data.damage *= 10.0
	# Set target for seeking munitions
	if controller:
		controller.set_data(dat)
	# Make it so a Ship can't shoot their own bullets.
	# More often this is making a shooter not shoot down
	# their own missiles, because most projectiles don't
	# have a hit_box_component, but some missiles do.
	if hit_box_component:
		hit_box_component.add_damage_exception(dat.shooter)
	# Override target in order to set target to be
	# centermost enemy.
	if autotarget:
		if dat.shooter and dat.shooter.is_in_group("red_team"):
			dat.target = Global.get_center_most_from_group("blue team",self)
		else:
			dat.target = Global.get_center_most_from_group("red team",self)
	# Set up timed fuse explosions and generally deal with timeout
	if explode_on_timeout and dat.target and is_instance_valid(dat.target):
		# Get distance to target intercept
		var intercept:Vector3 = Global.get_intercept(
					global_position, speed,
					dat.target)
		var dist := global_position.distance_to(intercept)
		# I have no ducking clue why speed needs multiplied
		# by 2, but I gathered data by manually adjusting
		# the timeout and distance and got the following
		# values to hit the player at a bullet speed of 500:
		# distance, timeout
		# (305.16226,0.295)
		# (219.750885,0.215)
		# (1368.4803,1.369)
		# If you plot those on a line, the line is almost exactly
		# y = x/1000
		# What I'd expect is
		# y = x/500   because speed was 500 for these tests
		# Therefore I multiply the speed by 2 and by God
		# that fixes the overshoot. Still don't know why.
		time_out = (dist/(speed*2))
		# Add in a random +- to the timeout.
		time_out += randf_range(-time_out*target_range_plus_minus, time_out*target_range_plus_minus)
	# Start the timer
	timer.start(time_out)


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


func _physics_process(delta: float) -> void:
	# If there is a ray and it collided, then it will
	# handle the rest.
	if ray and ray.did_collide(self, delta):
		return
	
	# Seeker missiles and other bullets might
	# use one of a number of different controllers
	# that modify the velocity.
	if controller:
		controller.move_me(self, delta)
	
	# Move forward
	global_position += velocity * delta
	
	# Roll a little because it looks good with contrails
	rotate_z(roll_amount*delta)
	# Tried some pitch, but it didn't add anything.
	#rotate_y(pitch_amount*delta)


func aim_self() -> void:
	# If aim assist is on and the target is valid, intercept
	# the target.
	if data.aim_assist and is_instance_valid(data.target):
		var intercept:Vector3 = Global.get_intercept(
			global_position, speed, data.target)
		look_at(intercept, Vector3.UP)
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
	else:
		# Point the projectile in the direction faced
		# by the gun and give the bullet the global
		# position of the gun
		global_transform = data.gun.global_transform
	# Apply spread and set velocity
	apply_spread(data)
	velocity = -global_transform.basis.z * speed


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


func damage_and_die(body, collision_point=null) -> void:
	if should_skip_body(body):
		return
	# Damage what was hit
	#https://www.youtube.com/watch?v=LuUjqHU-wBw
	if body.is_in_group("damageable"):
		body.damage(data.damage, data.shooter)
	# Previous was the damage part. Now do the dieing part.
	die_without_damaging(body, collision_point)


# Called by projectile.damage_and_die, but also called
# by RayCastForProjectiles.did_collide when collided with
# a non-damageable object
func die_without_damaging(body, collision_point=null) -> void:
	if should_skip_body(body):
		return
	# Play feedback for player if relevant
	Global.player_feedback(body, data)
	# Make a spark at collision point
	if collision_point:
		if body.is_in_group("shield"):
			VfxManager.play_with_transform(shieldSparks, collision_point, transform)
		else:
			VfxManager.play_with_transform(sparks, collision_point, transform)
	stop_near_miss_audio()
	VfxManager.play_with_transform(deathExplosion, global_position, transform)
	# Explode maybe
	if damaging_explosion:
		explode_with_damage()
	#Delete bullets that strike a body
	wrap_up()


# If the given body should not be collided with for any
# reason, then return true
func should_skip_body(body) -> bool:
	# Null instance can occur when body dies
	# from another source of damage while this
	# projectile is still trying to damage it.
	if !is_instance_valid(body):
		return true
	# Stop early for other collision exceptions.
	# This will be things like the shooter's hitbox
	# and shields.
	elif data.collision_exceptions.has(body):
		return true
	else:
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
	if explode_on_timeout:
		explode_with_damage()
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
		queue_free.call_deferred()
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
		elif child is SparkleTrailVisual:
			child.wrap_up()
		elif child.get('visible'):
			child.hide()
	# Start up a timer and queue_free all the rest when it goes off
	wrap_up_timer = Timer.new()
	add_child(wrap_up_timer)
	wrap_up_timer.timeout.connect(queue_free)
	wrap_up_timer.start(wrap_up_time)


# The next two methods are only used by projectiles
# that are using Area3Ds to detect collisions
func _on_area_entered(area: Area3D) -> void:
	# If we hit a near-miss detector
	if area.is_in_group("near-miss detector"):
		start_near_miss_audio()
	else:
		# Global position is where to show
		# sparks or other particle effects
		damage_and_die(area, global_position)


func _on_body_entered(body: Node3D) -> void:
	# Global position is where to show
	# sparks or other particle effects
	damage_and_die(body, global_position)


# For now, only projectiles with rays can ricochet
# Source at 6:30 here:
# https://www.youtube.com/watch?v=joMBVo_ZwKI
# It seems that the second ricochet is glitchy,
# though the first bounce works as expected.
# For now I'm moving on.
func ricochet(delta:float):
	# Move the bullet back to the point of collision
	global_position = ray.get_collision_point()
	# Remove 20% of the speed
	#speed = clampf(speed - speed*0.2, 0.0, 100000.0)
	#velocity = -transform.basis.z * speed
	# Bounce
	var norm := ray.get_collision_normal()
	velocity = velocity.bounce(norm)
	# In the video, the creator uses Global.safe_look_at
	# which I assume is something he created after
	# getting errors from using look_at
	# You might consider creating your own
	# based on the code in the stick_decal function
	# which also had to deal with look_at bugs.
	look_at(global_transform.origin - velocity)
	# Move away from collision location to avoid
	# touching it on the next frame.
	# 1.1 to give that 10% extra assurance of not
	# recolliding.
	global_position += velocity * delta * 1.1


func explode_with_damage() -> void:
	# Add an explosion to main_3d and properly
	# queue free this ship
	var explosion = damaging_explosion.instantiate()
	# Add to main_3d, not root, otherwise the added
	# node might not be properly cleared when
	# transitioning to a new scene.
	Global.main_scene.main_3d.add_child(explosion)
	# Set explosion's position and damage
	explosion.global_position = global_position
	explosion.damage_amt = data.damage
	# I got an invalid assignment on 
	# explosion.shooter = data.shooter
	# so I slapped on this if to try to avoid it.
	if is_instance_valid(data.shooter):
		explosion.shooter = data.shooter
