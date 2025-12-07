class_name Gun extends Node3D

# What sort of bullet to fire:
@export var bullet: PackedScene

@export var damage:float = 1.0
@export var bullet_speed:float = 1000.0
@export var bullet_timeout:float = 2.0 ## Seconds

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

# Gun animation, for example, rotation of the gatling gun.
# Also the muzzle flash
@export var gun_animation : AnimationPlayer
@export var muzzle_flash:Node3D # This requires only a play button

# Only guns that actually use a raycast3d should
# have a ray, such as guns that fire laser guided
# munitions.
var ray : RayCast3D
# Reticle, if any, to use for this gun. This should ONLY
# be attached as a child of the gun on player-controlled
# ships.
var reticle:TextureRect

# So guns can know what team they're on
var ally_team:String


# Called when the node enters the scene tree for the first time.
func _ready():
	current_mag = magazine_size
	# The new laser doesn't use a firing rate timer or reload timer.
	if has_node("FiringRateTimer"):
		firing_rate_timer = $FiringRateTimer
	if has_node("ReloadTimer"):
		reload_timer = $ReloadTimer
	# Search through children for various components
	# and save a reference to them.
	for child in get_children():
		if child is RayCast3D:
			ray = child
		elif child is TextureRect:
			reticle = child
	# Calculate bullet range
	range_sqd = (bullet_speed*bullet_timeout)*(bullet_speed*bullet_timeout)


func _process(_delta: float) -> void:
	if reticle:
		var position_ahead:Vector3 = global_position - global_transform.basis.z*500.0
		Global.set_reticle(null, reticle, position_ahead)


func ready_to_fire() -> bool:
	# The laser beam doesn't use a firing_rate_timer
	# so first check if that exists.
	return (!firing_rate_timer or firing_rate_timer.is_stopped()) and current_mag > 0


func shoot(shooter:Node3D, target:Node3D=null, powered_up:bool=false) -> void:
	if !ready_to_fire():
		return
	# Animate 'em if you got 'em
	if gun_animation:
		gun_animation.play("gun_animation")
	# Play muzzle flash effect
	if muzzle_flash:
		muzzle_flash.play()
	# create fire audio stream
	if fire_sound != SoundEffectSetting.SOUND_EFFECT_TYPE.NONE:
		fire_sound_active = AudioManager.play_remote_transform(fire_sound, self)
	restart_timer()
	setup_shoot_data(shooter,target,powered_up)
	shoot_actual()


func restart_timer() -> void:
	if firing_rate_timer:
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
	# Only use aim assist if it's set up on the shooter
	# and the target reference is valid
	# AND the gun only fires one bullet at a time.
	# Spread shot weapons should not use aim assist.
	if "aim_assist" in shooter and shooter.aim_assist and simultaneous_shots == 1 and target and is_instance_valid(target):
		data.aim_assist = shooter.aim_assist.use_aim_assist(shooter, target, bullet_speed)


func shoot_actual() -> void:
	for i in range(simultaneous_shots):
		# Create and fire bullet(s)
		var b = bullet.instantiate()
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
	if gun_animation:
		gun_animation.stop()
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
