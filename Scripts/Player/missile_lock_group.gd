extends Node3D
class_name MissileLockGroup

# This uses images from the kenney crosshair pack
# https://kenney.nl/assets/crosshair-pack

# If this is true, then this missile lock group
# is intended for npc use only. It will not
# use any targeting reticles or audio, and
# it will never depend on the camera.
# Instead, the missile lock will have a timer
# that counts down to lock and the timer
# can go slower or faster depending on the npc's
# angle to target. Lock can still be broken
# by target leaving range missile_range_sqd
# or by angle to target exceeding missile_lock_max_angle
@export var npc_missile_lock:bool = false ## True if for npc use. Eliminates a lot of audio visual stuff that only humans need.
@export var lock_timeout:float = 4.0 ## Time in seconds needed to acquire lock
# Used to count down time to lock
var lock_timer:float = 0.0
# angle within which lock timer goes twice as fast
var faster_lock_angle:float = 5.0 # degrees
# angle beyond which which lock timer increases rather than decreases
var slower_lock_angle:float = 25.0 # degrees

# Gun to fire when launch is triggered
var missile_launcher:Gun

@export var missile_range:float = 300.0 ## Range within which missile lock can be acquired.
# Calculated from missile_range
var missile_range_sqd:float ## Squared range within which missile lock can be acquired
@export var missile_lock_max_angle:float = 35.0 ## In degrees. Can achieve and maintain missile lock if target is within plus of minus of this angle from center.

# Track time since missile lock acquired
var time_since_lock:float = 0.0
# Then if missile is fired within this interval,
# give the missile more damage or better
# tracking or something
@export var quick_launch_interval = 0.1 # seconds

# Reference to the target so we can track it
var target:Node3D
# TextureRect used for the reticle when still
# acquiring target
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

# Distance multiplier for how far from onscreen position
# of target to put the reticle when it's first shown
# on screen.
@export var distance_multiplier:float = 3.0

# Squared distance at which to transition
# into the locked state
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

# The following two variables get set by team_setup.gd
var ally_team:String
var enemy_team:String


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	missile_range_sqd = missile_range*missile_range
	acquiring_offset = acquiring.size/2.0
	acquiring.hide()
	lock_offset = lock.size/2.0
	lock.hide()
	# Search through children for gun to use
	# as missile launcher.
	for child in get_children():
		if child is Gun:
			missile_launcher = child
	# If this is an NPC missile lock group, then
	# queue free all children of this node EXCEPT
	# for the gun / missile_launcher.
	# They aren't needed.
	if npc_missile_lock:
		for c in get_children():
			if missile_launcher != c:
				c.queue_free()


# Ship that this scene is a child of ought to be the
# targeter. This function will be called from
# physics_process with delta as elapsed time.
func update(targeter:Node3D, delta: float) -> void:
	# NPCs attempt to start seeking at all times
	if npc_missile_lock and !seeking:
		attempt_to_start_seeking(targeter)
	# If the target is invalid, stop seeking (if we were)
	# and do nothing further in this function
	if !is_instance_valid(target):
		if seeking:
			stop_seeking()
	# Also stop seeking if target is out of range or offscreen
	elif seeking and \
	(targeter.global_position.distance_squared_to(target.global_position) > missile_range_sqd \
	or Global.get_angle_to_target(targeter.global_position, target.global_position, -targeter.global_basis.z) > deg_to_rad(missile_lock_max_angle)):
		stop_seeking()
		target.lost_lock(targeter)
	# Otherwise target is valid and we're either seeking
	# or locked.
	else:
		if npc_missile_lock:
			if seeking:
				npc_seeking_update(targeter, delta)
			if locked:
				attempt_to_fire_missile(targeter)
		else: # Player missile lock behavior follows
			# Get onscreen position of target
			var target_onscreen:Vector2 = Global.current_camera.unproject_position(target.global_position)
			if seeking:
				# Move reticle into position and, if it's
				# close enough, acquire lock
				continue_seeking(delta, target_onscreen, targeter)
			# It seems like this should be an elif,
			# but there's a messy little one frame
			# flicker between the reticles if you
			# make it an elid, so don't!
			if locked:
				time_since_lock += delta
				lock.set_global_position(target_onscreen - lock_offset)


func npc_seeking_update(targeter:Node3D, delta:float) -> void:
	var angle_to:float = rad_to_deg(Global.get_angle_to_target(targeter.global_position, target.global_position, -targeter.global_basis.z))
	if angle_to < faster_lock_angle:
		# lock timer goes twice as fast
		lock_timer -= 2.0*delta
	elif slower_lock_angle < angle_to:
		# lock timer increases rather than decreases
		# up to the lock_timeout amount
		lock_timer = min(lock_timer+delta, lock_timeout)
	else:
		# Normal amount of time passes
		lock_timer -= delta
	# Check for lock on
	if lock_timer < 0.0:
		locked = true
		seeking = false
		target.lock_acquired(targeter)


# Try to begin seeking target as long as
# there exists a valid target and the
# missile launcher is cooled down and ready.
# If no target currently exists, the centermost
# from targeter's perspective will be sought.
func attempt_to_start_seeking(targeter:Node3D) -> void:
	# Unset previous target if any
	var old_target = null
	if is_instance_valid(target):
		target.set_targeted(targeter, false)
		old_target = target
		target = null
	# If targeter already has a target, use it
	if targeter.controller and targeter.controller.target and is_instance_valid(targeter.controller.target):
		target = targeter.controller.target
	else:
		# Target most central enemy team member
		target = Global.get_center_most_from_group(enemy_team,targeter)
	# If target is valid and missile is off cooldown,
	# tell target that missile lock is being sought on
	# it and start the seeking audio and visual
	if is_instance_valid(target):
		# If there was an old target and it's not
		# the same as the new target, then tell
		# old target that it's no longer locked on to
		if old_target and old_target != target:
			old_target.lost_lock(targeter)
		# set_targeted is called on a hitbox component
		# and merely modulates the reticle color (for now)
		# In the future, you might want to do
		# this differently. Currently, this is also
		# called in the player's controller, but is
		# not otherwise called by NPCs
		target.set_targeted(targeter, true)
		# Create missile reticle and put it on the screen
		# only if another missile is ready to fire
		if missile_launcher.ready_to_fire():
			start_seeking()
			target.seeking_lock(targeter)


# Fire missile if lock is acquired
func attempt_to_fire_missile(targeter:Node3D) -> void:
	if locked:
		launch(targeter)
		# Tell the target that it's got a missile inbound
		target.missile_inbound(targeter)
	stop_seeking()


func start_seeking() -> void:
	seeking = true
	if npc_missile_lock:
		# Reset lock_timer.
		lock_timer = lock_timeout
		return
	# Otherwise run the code for a player,
	# which includes audio and visuals.
	var target_onscreen:Vector2 = Global.current_camera.unproject_position(target.global_position)
	# Make reticle approach the target from the far side of
	# center screen relative to the target's on-screen position.
	# First, get the position of the target as if 0,0 was center screen
	reticle_position = (DisplayServer.window_get_size()/2.0) - target_onscreen
	# Then adjust that position to the far side of center.
	reticle_position = distance_multiplier*reticle_position + target_onscreen
	# Don't beep immediately. Don't show immediately and
	# give max delay audio delay.
	# The beep and flicker of the reticle are annoying when
	# you're just retargeting. I moved acquiring.show() to
	# the timeout of the audio timer.
	audio_timer.start(repeat_tone_max_time)


# Move reticle into position and, if it's close enough,
# acquire lock
func continue_seeking(delta:float, target_onscreen:Vector2, targeter:Node3D) -> void:
	# Move reticle either with lerp or move_toward
	if use_lerp:
		lerp_weight += delta/lerp_modifier
		reticle_position = lerp(reticle_position, target_onscreen, lerp_weight)
	else:
		reticle_position = reticle_position.move_toward(target_onscreen, delta*speed)
	# "acquiring" is the reticle. Position it on screen
	acquiring.set_global_position(reticle_position - acquiring_offset)
	# Check if lock acquired
	dist_tween_reticles = target_onscreen.distance_squared_to(reticle_position)
	#print(int(sqrt(dist_tween_reticles)))
	if dist_tween_reticles < lock_dist_sqd:
		acquire_lock()
		target.lock_acquired(targeter)
		# Subract delta here because we're
		# about to add delta in the "if locked"
		#in the update function, but we
		# don't want to actually count this
		# delta time (on this frame where we
		# only just acquired lock) as time
		# since lock. So this cancels out
		# the addition of delta in update.
		time_since_lock -= delta


# Scale the audio delay with distance to target.
# Return a value between repeat_tone_min_time and repeat_tone_max_time
func get_audio_delay() -> float:
	return min(dist_tween_reticles/distance_scaling, 1.0) * (repeat_tone_max_time - repeat_tone_min_time) + repeat_tone_min_time


func stop_seeking() -> void:
	seeking = false
	locked = false
	time_since_lock = 0.0
	if !npc_missile_lock:
		acquiring.hide()
		lock.hide()
		lerp_weight = 0.0
		seeking_audio.stop()
		locked_audio.stop()


# Fire the missiles!
func launch(targeter:Node3D) -> void:
	# Determine if this is a quick launch
	var is_quick_launch:bool = time_since_lock <= quick_launch_interval
	# If the is not an npc missile lock then play audio
	if !npc_missile_lock:
		if is_quick_launch:
			quick_launch_audio.play()
		else:
			launch_audio.play()
	# Fire zee missile! (For now, don't let npcs use quick launch)
	missile_launcher.shoot(targeter, target, is_quick_launch and !npc_missile_lock)


func acquire_lock() -> void:
	acquiring.hide()
	lock.show()
	locked = true
	locked_audio.play()
	seeking = false


# Replay the seeking audio
func _on_audio_timer_timeout() -> void:
	if seeking and !locked:
		acquiring.show()
		seeking_audio.play()
		audio_timer.start(get_audio_delay())
