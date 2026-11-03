extends Node3D

# The goal is to cache every single vfx by playing it once
# in front of a camera.

signal caching_completed

@onready var camera: Camera3D = $Camera3D
# Node where vfx will be played
@onready var loc: Node3D = $StartNode
# Just an extra time buffer for now before emitting signal
@onready var timer: Timer = $Timer

# Array of all the vfx enum values
var vfx_enums:Array
# Array of all the bullet enum values
var bullet_enums:Array
# To track whether or not we're finished with vfx
# and ready to move on to bullets
var done_with_vfx:bool = false
# Use index to start one effect per frame
var index:int = 0


# Get all the enum values
func _ready() -> void:
	vfx_enums = VisualEffectSetting.VISUAL_EFFECT_TYPE.values()
	bullet_enums = BulletSpawner.BULLET_TYPE.values()
	
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
func _process(_delta: float) -> void:
	# If we've reached the end of vfx, reset to
	# go through bullets.
	if vfx_enums.size() <= index:
		done_with_vfx = true
		index = 0
	# If we've reached the end of bullets, stop.
	if done_with_vfx and bullet_enums.size() <= index:
		set_process(false)
		# Start a timer to give a short buffer before
		# emitting the 'caching_completed' signal.
		timer.start()
		return
	if done_with_vfx:
		# Skip placeholder enum
		if bullet_enums[index] != BulletSpawner.BULLET_TYPE.DUMMY_PLACEHOLDER:
			# Spawn next bullet
			var p:Projectile = BulletSpawner.new_bullet(bullet_enums[index])
			p.data = ShootData.new()
			loc.add_child(p)
			p.look_at(camera.global_position, Vector3.UP)
	else:
		# Play next visual effect
		VfxManager.play(vfx_enums[index], loc.global_position)
	index += 1


func _on_timer_timeout() -> void:
	caching_completed.emit()
