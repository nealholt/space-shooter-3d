extends Node3D
class_name MissileLockGroup

# This uses images from the kenney crosshair pack
# https://kenney.nl/assets/crosshair-pack

# Gun to fire when launch is triggered
@export var missile_launcher:Gun

# Squared range within which missile lock can be acquired
@export var missile_range_sqd:float = 300.0**2
# Can achieve and maintain missile lock if target is
# within plus of minus of this angle from center.
@export var missile_lock_max_angle:float = 35.0 # degrees

# Track time since missile lock acquired
var time_since_lock:float = 0.0
# Then if missile is fired within specific interval,
# give the missile more damage or better tracking or something
@export var quick_launch_interval = 0.1 # seconds

# Reference to the target so we can track it
var target:Node3D
# TextureRect used for the reticle when still acquiring target
@onready var acquiring: TextureRect = $AcquiringTargetReticle
# Half the width of the acquiring TextureRect to display it centered
var acquiring_offset:Vector2
# TextureRect used for the reticle when lock is acquired
@onready var lock: TextureRect = $TargetLockReticle
# Half the width of the lock TextureRect to display it centered
var lock_offset:Vector2
# Current onscreen position of reticle
var reticle_position:Vector2
# Whether or not we are in the seeking state
var seeking:bool = false
# Whether or not we are in the locked state
var locked:bool = false

# Speed at which reticle approaches target when use_lerp
# is false measured in onscreen pixels per second (I think)
@export var speed:float = 250.0

# Whether to lerp reticle to target or use move_toward
@export var use_lerp:bool = false

# Lerping reticle to target has a distinct feel and
# it's not bad. I'm not sure which I prefer so I'm
# keeping both for now.
@export var lerp_modifier:float = 12.0
# lerp_weight accumulates over time until it's at 100 percent
var lerp_weight:float = 0.0

# Distance multiplier for how far to start the acquiring
# reticle away from its target
@export var distance_multiplier:float = 3.0

# Squared distance at which to transition into the locked state
@export var lock_dist_sqd:float = 6.0

# Both missile lock audio clips were created here:
# https://sfxr.me/
# acquiring_lock.wav:
# https://sfxr.me/#3B4oczToDBf1ZudxJw3eXW3pRnb7c5EP2PZ3gcmDCQEa2qwdmPJzCHsycsMbZL7sRheQVGD4easck8q3zUazWYcAxZFmi98xssZFTcX3j3uL35AgMbPvmemQq
# missile_lock.wav:
# https://sfxr.me/#34T6PkicSdTU6KhbhjVmvuFsFxX1veMozKSTNVivzWmspYaK5BW7Ud7jbTsau4Nwj1emeASrXWm3dCnqDHPsJqr6JLfZGAxofPYWSH2WeidNBm2X6UKEoYLeT
# launch.wav:
# https://sfxr.me/#7BMHBGRSn16EV8KpNM4j9ES6TKTjQK7e2qFNdTg4UbAVtywt4433xC2Upgro2nAYUC1d2NSxYWqrKfPTd9gkSWYf2KK8jSYkyxvZp4qpu3zkt5NzQVfRzDo83
# quick_launch.wav:
# https://sfxr.me/#8ch7UZPD3piysvVk2KvB9bUgyCwkoLH4BhzF2oNUGJN39wwnhbWxZiKETKMD7sFvh3GCSRKHDpnh4p2DHn7Ug9DfVNm3k7pBFCRZYG1r7NtXbzr1HCpudsSG6
@onready var seeking_audio: AudioStreamPlayer = $SeekingAudio
@onready var locked_audio: AudioStreamPlayer = $LockedAudio
@onready var launch_audio: AudioStreamPlayer = $LaunchAudio
@onready var quick_launch_audio: AudioStreamPlayer = $QuickLaunchAudio
# There's got to be a better way to repeat the seeking tone
var repeat_tone_max_time:float = 0.5 # seconds
var repeat_tone_min_time:float = 0.05 # seconds
# Scale time between beeps with reticle distance to target
var distance_scaling: = 70.0**2
# Onscreen distance between reticle and target
var dist_tween_reticles:float
@onready var audio_timer: Timer = $AudioTimer

var ally_team:String
var enemy_team:String


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	acquiring_offset = acquiring.size/2.0
	acquiring.hide()
	lock_offset = lock.size/2.0
	lock.hide()


# Ship that this scene is a child of ought to be the
# targeter. Its target is targeted. This will be called
# from physics_process with delta as elapsed time.
func update(targeter:Node3D, delta: float) -> void:
	# Target most centered enemy and begin missile lock
	if Input.is_action_just_pressed("right_shoulder"):
		# Unset previous target if any
		if is_instance_valid(target):
			target.set_targeted(false)
			target = null
		# Target most central enemy team member
		target = Global.get_center_most_from_group(enemy_team,targeter)
		if is_instance_valid(target):
			target.set_targeted(true)
			# Create missile reticle and put it on the screen
			start_seeking()
	# Fire missile if lock is acquired
	if Input.is_action_just_released("right_shoulder"):
		if locked:
			missile_launcher.shoot(targeter, target, launch())
		stop_seeking()
	# Stop seeking if target no longer valid or out of range or offscreen
	if seeking and \
	(!is_instance_valid(target) or \
	targeter.global_position.distance_squared_to(target.global_position) > missile_range_sqd \
	or Global.get_angle_to_target(targeter.global_position, target.global_position, -targeter.global_basis.z) > deg_to_rad(missile_lock_max_angle)):
		stop_seeking()
	
	if !is_instance_valid(target):
		stop_seeking()
	else:
		var target_onscreen:Vector2 = Global.current_camera.unproject_position(target.global_position)
		if seeking:
			# Move reticle either with lerp or move_toward
			if use_lerp:
				lerp_weight += delta/lerp_modifier
				reticle_position = lerp(reticle_position, target_onscreen, lerp_weight)
			else:
				reticle_position = reticle_position.move_toward(target_onscreen, delta*speed)
			acquiring.set_global_position(reticle_position - acquiring_offset)
			# Check if lock acquired
			dist_tween_reticles = target_onscreen.distance_squared_to(reticle_position)
			#print(int(sqrt(dist_tween_reticles)))
			if dist_tween_reticles < lock_dist_sqd:
				acquiring.hide()
				lock.show()
				locked = true
				locked_audio.play()
				time_since_lock -= delta
		if locked:
			time_since_lock += delta
			lock.set_global_position(target_onscreen - lock_offset)


func start_seeking() -> void:
	var target_onscreen:Vector2 = Global.current_camera.unproject_position(target.global_position)
	# Make reticle approach the target from the far side of
	# center screen relative to the target's on-screen position.
	# First, get the position of the target as if 0,0 was center screen
	reticle_position = (DisplayServer.window_get_size()/2.0) - target_onscreen
	# Then adjust that position to the far side of center.
	reticle_position = distance_multiplier*reticle_position + target_onscreen
	seeking = true
	# Don't beep immediately. Don't show immediately and
	# give max delay audio delay.
	# The beep and flicker of the reticle are annoying when
	# you're just retargeting. I moved acquiring.show() to
	# the timeout of the audio timer.
	#acquiring.set_global_position(reticle_position - acquiring_offset)
	#acquiring.show()
	#seeking_audio.play()
	#dist_tween_reticles = target_onscreen.distance_squared_to(reticle_position)
	audio_timer.start(repeat_tone_max_time)


# Scale the audio delay with distance to target.
# Return a value between repeat_tone_min_time and repeat_tone_max_time
func get_audio_delay() -> float:
	return min(dist_tween_reticles/distance_scaling, 1.0) * (repeat_tone_max_time - repeat_tone_min_time) + repeat_tone_min_time


func stop_seeking() -> void:
	seeking = false
	locked = false
	acquiring.hide()
	lock.hide()
	lerp_weight = 0.0
	seeking_audio.stop()
	locked_audio.stop()
	time_since_lock = 0.0


# Returns true if this was a quick launch
func launch() -> bool:
	if time_since_lock <= quick_launch_interval:
		quick_launch_audio.play()
		return true
	else:
		launch_audio.play()
		return false


# Replay the seeking audio
func _on_audio_timer_timeout() -> void:
	if seeking and !locked:
		acquiring.show()
		seeking_audio.play()
		audio_timer.start(get_audio_delay())
