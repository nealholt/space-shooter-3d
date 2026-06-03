class_name Gun extends Node3D

# Detects shields that this gun has entered
# in order to exempt them from collisions.
# In short, let this gun fire from within shields.
@onready var shield_detector: Area3D = $ShieldDetector
# Bullets fired by this gun should ignore collisions
# with anything in this array
var collision_exceptions := Array()

# What sort of bullet to fire:
@export var bullet_type:BulletSpawner.BULLET_TYPE

@export var damage:float = 1.0
@export var bullet_speed:float = 1000.0
@export var bullet_timeout:float = 2.0 ## Seconds
@export var timeout_vary_percent:float = 0.05 ## Randomly vary the timeout by this percent

@export var fire_rate:= 1.0 ## Shots per second
var firing_rate_timer: Timer

# Whether gun is automatic or not. If true then
# holding the shoot button will fire this weapon
# as often as possible.
# If false, then this weapon will only fire when
# shoot is first pressed. Shoot must then be
# released and pressed again before firing.
@export var automatic:bool = true

# Later in the code I convert spread_deg to radians
# and cut it in half so that the spread total is
# spread_deg rather than plus or minus spread_deg,
# which makes it twice as large.
@export var spread_deg:float = 0.0 # degrees

## How many bullets to spawn simultaneously
@export var simultaneous_shots:int = 1

# Struct containing info about how and where to shoot
# and who the shooter is
var data:ShootData

# Squared range of the gun based on bullet speed
# and bullet duration
var range_sqd:float

@export var fire_sound: SoundEffectSetting.SOUND_EFFECT_TYPE = SoundEffectSetting.SOUND_EFFECT_TYPE.NONE
var fire_sound_active:SoundEffectSetting.SOUND_EFFECT_TYPE = SoundEffectSetting.SOUND_EFFECT_TYPE.NONE
@export var reload_sound: SoundEffectSetting.SOUND_EFFECT_TYPE = SoundEffectSetting.SOUND_EFFECT_TYPE.NONE

const INFINITE_AMMO:int = 2**30-1
@export var magazine_size:int = INFINITE_AMMO ## Default is infinite ammo, no reload
var current_mag:int
@export var reload_time:= 1.0 ## seconds
var reload_timer:Timer

# Gun visual components
@export var gun_model : GunModel
@export var muzzle_flash : MuzzleFlash

# Only guns that actually use a raycast3d should
# have a ray, such as guns that fire laser guided
# munitions.
@export var ray : RayCast3D
# Reticle, if any, to use for this gun. This should ONLY
# be attached as a child of the gun on player-controlled
# ships.
@export var reticle : TextureRect

# So guns can know what team they're on
var ally_team:String


# Called when the node enters the scene tree for the first time.
func _ready():
	# The new laser doesn't use a firing rate timer or reload timer.
	if has_node("FiringRateTimer"):
		firing_rate_timer = $FiringRateTimer
	if has_node("ReloadTimer"):
		reload_timer = $ReloadTimer
	# Detect when entering or exiting shields
	shield_detector.area_entered.connect(_on_shield_entered)
	shield_detector.area_exited.connect(_on_shield_exited)
	# Set some non-export variables
	set_initial_values()


func set_initial_values() -> void:
	current_mag = magazine_size
	# Calculate bullet range
	range_sqd = (bullet_speed*bullet_timeout)*(bullet_speed*bullet_timeout)


# For now, just copy the stats over
func setup_from_resource(gun_stats:GunStats, is_player:bool) -> void:
	# Copy over everything from the gun stats resource
	# to instance variables.
	bullet_type = gun_stats.bullet_type
	damage = gun_stats.damage
	bullet_speed = gun_stats.bullet_speed
	bullet_timeout = gun_stats.bullet_timeout
	timeout_vary_percent = gun_stats.timeout_vary_percent
	fire_rate = gun_stats.fire_rate
	magazine_size = gun_stats.magazine_size
	reload_time = gun_stats.reload_time
	automatic = gun_stats.automatic
	spread_deg = gun_stats.spread_deg
	simultaneous_shots = gun_stats.simultaneous_shots
	fire_sound = gun_stats.fire_sound
	reload_sound = gun_stats.reload_sound
	position = gun_stats.position
	if gun_stats.muzzle_flash:
		muzzle_flash = gun_stats.muzzle_flash.instantiate()
		add_child(muzzle_flash)
		muzzle_flash.rotation_degrees = Vector3(0.0, -180.0, 0.0)
	# Only player guns have reticles
	if is_player and gun_stats.reticle:
		reticle = TextureRect.new()
		reticle.texture = gun_stats.reticle
		reticle.size = Vector2(64,64)
		reticle.self_modulate = Color(1.0,1.0,1.0,0.6)
		add_child(reticle)
	if gun_stats.gun_model:
		gun_model = gun_stats.gun_model.instantiate()
		add_child(gun_model)
		gun_model.position = gun_stats.model_adjust
	# If the bullets are laser guided and there is not
	# already a ray cast attached, then attach one
	if bullet_type == BulletSpawner.BULLET_TYPE.LASER_GUIDED_MISSILE and !ray:
		ray = RayCast3D.new()
		ray.enabled = false
		# The -10000 on the next line is a magic number,
		# but it's probably fine. All we need is a point
		# waaay in front of the gun.
		ray.target_position = Vector3(0.0, 0.0, -10000.0)
		ray.collision_mask = Global.BODY_COLL_LAYER + \
					Global.BULLET_COLL_LAYER + \
					Global.SHIELD_COLL_LAYER + \
					Global.HITBOX_COLL_LAYER
		ray.collide_with_areas = true
		add_child(ray)
	# The only thing _process does is update the reticle
	set_process(is_player and gun_stats.reticle)
	# What needs done afterward? like what's done in _ready, but should also be done here
	set_initial_values()


func _process(_delta: float) -> void:
	if reticle:
		var position_ahead:Vector3 = global_position - global_transform.basis.z*500.0
		Global.set_reticle(reticle, position_ahead)
	# One of the problems with the next bit is that it breaks gun
	# variants (such as burst gun or laser gun) that also use the
	# _process function when you don't attach a reticle to them.
	#else:
		## This function doesn't do anything else,
		## so shut itself down.
		#set_process(false)


func ready_to_fire() -> bool:
	# The laser beam doesn't use a firing_rate_timer
	# so first check if that exists.
	return (!firing_rate_timer or firing_rate_timer.is_stopped()) and current_mag > 0


func shoot(shootDat:ShootData) -> void:
	if !ready_to_fire():
		return
	# Animate 'em if you got 'em
	if gun_model:
		gun_model.shoot()
	# Play muzzle flash effect
	if muzzle_flash:
		muzzle_flash.play()
	# create fire audio stream
	if fire_sound != SoundEffectSetting.SOUND_EFFECT_TYPE.NONE:
		fire_sound_active = AudioManager.play_remote_transform(fire_sound, self)
	restart_timer()
	# Copy ShootData reference and further populate it
	data = shootDat
	# Fire from the position of the gun
	data.gun = self
	data.damage = damage
	data.bullet_speed = bullet_speed
	data.bullet_timeout = bullet_timeout
	data.timeout_vary_percent = timeout_vary_percent
	data.spread_deg = spread_deg
	# Add the raycast to the shoot_data for
	# reference by laser-guided projectiles
	data.ray = ray
	# Set the aim assist bool based on the data
	# provided to ShootData. 
	data.determine_aim_assist(simultaneous_shots)
	# Add in collision exceptions
	data.collision_exceptions = data.collision_exceptions + collision_exceptions
	# Actually shoot
	shoot_actual()


# Firing rate is shots per seconds, so the seconds per shot
# is the inverse of that.
func restart_timer() -> void:
	if firing_rate_timer:
		firing_rate_timer.start(1.0/fire_rate)


func shoot_actual() -> void:
	for i in range(simultaneous_shots):
		# Create and fire bullet(s)
		var b:Projectile = BulletSpawner.new_bullet(bullet_type)
		# Add to team group
		Global.add_to_team_group(b, ally_team)
		# Pass the bullet the data about the shooter,
		# initial velocity, etcetera
		b.set_data(data)
	# Spend bullets unless they are supposed to be infinite
	if magazine_size != INFINITE_AMMO:
		current_mag -= simultaneous_shots
		# Begin reload
		if current_mag <= 0:
			reload()


# Called by weapon handler when switching to a
# different weapon
func deactivate() -> void:
	# Reload if at anything less than a full mag
	if current_mag < magazine_size:
		reload()
	#visible = false
	set_process(false)
	set_physics_process(false)
	if reticle:
		reticle.hide()
	if gun_model:
		gun_model.stop_animating()
	# Interrupt firing sound
	if fire_sound_active != SoundEffectSetting.SOUND_EFFECT_TYPE.NONE:
		AudioManager.stop(fire_sound, fire_sound_active, true)
	if ray:
		ray.enabled = false


# Called by weapon handler when switching to
# this weapon
func activate() -> void:
	visible = true
	set_process(true)
	set_physics_process(true)
	if reticle:
		reticle.show()
	if ray:
		ray.enabled = true


func _on_reload_timer_timeout() -> void:
	current_mag = magazine_size


func reload() -> void:
	reload_timer.start(reload_time)
	if reload_sound != SoundEffectSetting.SOUND_EFFECT_TYPE.NONE:
		AudioManager.play_remote_transform(reload_sound, self)


func _on_shield_entered(area: Area3D) -> void:
	collision_exceptions.push_back(area)
func _on_shield_exited(area: Area3D) -> void:
	collision_exceptions.erase(area)
