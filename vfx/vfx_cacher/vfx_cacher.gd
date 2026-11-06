extends Node3D

# The goal is to cache every single vfx by playing it once
# in front of a camera.
# https://www.reddit.com/r/godot/comments/1xi8ol4/how_best_to_cache_particle_materials_to_avoid_lag/

signal caching_progress(percent:float) # percent will be 0 to 1
signal caching_completed

@onready var camera: Camera3D = $Camera3D
# Node where vfx will be played
@onready var loc: Node3D = $StartNode
# Just an extra time buffer for now before emitting signal
@export var extra_wait:float = 2.0 ## Seconds

# Array of all the vfx enum values
var vfx_enums:Array
# Array of all the bullet enum values
var bullet_enums:Array
# To track whether or not we're finished with vfx
# and ready to move on to bullets
var done_with_vfx:bool = false
# Use index to start one effect per frame
var index:int = 0
var wait_countdown:float


# Get all the enum values
func _ready() -> void:
	vfx_enums = VisualEffectSetting.VISUAL_EFFECT_TYPE.values()
	bullet_enums = BulletSpawner.BULLET_TYPE.values()
	wait_countdown = extra_wait
	
	# General housekeeping that every level is expected
	# to perform upon instantiation:
	Global.current_camera = camera
	# Create a ray on demand and attach it as a child
	RayOnDemand.new_ray(self)
	# This next bit doesn't work because there's no world
	# environment.
	# Create an environment tweener, attach it as a child,
	# and tell it to copy baseline environment values
	#var envt :EnvironmentTweener = EnvironmentTweener.new_environment_tweener(self)
	#envt.backup_environment_baselines.call_deferred($WorldEnvironment.environment)


# Play one effect per frame.
# Stop after all the effects have played.
func _process(delta: float) -> void:
	# If we've reached the end of vfx, reset to
	# go through bullets.
	if vfx_enums.size() <= index:
		done_with_vfx = true
		index = 0
	# If we've reached the end of bullets, wait another short
	# period of time to let the effects finish, then stop.
	if done_with_vfx and bullet_enums.size() <= index:
		wait_countdown -= delta
		# Final 2/3 to 3/3 progress
		caching_progress.emit(0.666 + (1.0 - wait_countdown/extra_wait)/3.0)
		if wait_countdown <= 0.0:
			caching_completed.emit()
			set_process(false)
		return
	if done_with_vfx:
		# Skip placeholder enum
		if bullet_enums[index] != BulletSpawner.BULLET_TYPE.DUMMY_PLACEHOLDER:
			# Spawn next bullet
			var p:Projectile = BulletSpawner.new_bullet(bullet_enums[index])
			p.data = ShootData.new()
			loc.add_child(p)
			p.look_at(camera.global_position, Vector3.UP)
			# Emit up to 2/3 progress for bullets
			caching_progress.emit(0.333 + (float(index)/bullet_enums.size())/3.0)
	else:
		# Play next visual effect
		VfxManager.play(vfx_enums[index], loc.global_position)
		# Emit up to 1/3 progress for visual effects
		caching_progress.emit((float(index)/vfx_enums.size())/3.0)
	index += 1
