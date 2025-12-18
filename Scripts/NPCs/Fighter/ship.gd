class_name Ship extends CharacterBody3D

signal destroyed

var aim_assist:AimAssist
var burning_trail:BurningTrail # This is a visual effect
var camera_group:CameraGroup
var controller:CharacterBodyControlParent
var engineAV:EngineAV
var health_component:HealthComponent
var missile_lock:MissileLockGroup
var weapon_handler:WeaponHandler

# For testing purposes, I want some ships to just sit there
# and do nothing. This is easy for fighters and corvettes
# because by default they do not have a controller attached
# to them because they could be player or NPC controlled.
# However, capital ships DO have controllers attached so
# this bool here disables them.
@export var disable_for_testing := false

# The following is so different ships can have different
# camera positions.
# Why in the name of the seven new gods and the old gods beyond
# counting would the correct cam_rotation_deg be -135 y?
@export var fps_cam_position := Vector3(0, 0, 0)
@export var fps_cam_rotation_deg := Vector3(0, -135, 0)
@export var side_cam_position := Vector3(0, 0, 0)
@export var side_cam_rotation_deg := Vector3(0, -135, 0)

# I added the following in so I could parameterize the
# PlayerCorvette differently on the asteroids level.
# This is probably hacky and bad, but whatever.
@export var impulse_std:float = -1.0 ## standard impulse. If -1 is used, default controller values will be used.
@export var impulse_accel:float = -1.0 ## acceleration impulse. If -1 is used, default controller values will be used.

# Maximum collision damage is received at 180 degree
# collisions (head on). Collision damage drops off
# linearly down to 1 at the minimum at 90 degrees or less.
# This is collision damage received.
# For now I'm not factoring in if a large object
# hits a small object, or the speed of collision.
@export var max_collision_damage:float = 10.0


var death_animation_timer:Timer
# The deathExplosion happens when the ship
# is first killed. Then the finalExplosion
# happens after the death animation completes.
# This, like many other things, was inspired
# by House of the Dying Sun.
@export var deathExplosion:VisualEffectSetting.VISUAL_EFFECT_TYPE
@export var finalExplosion:VisualEffectSetting.VISUAL_EFFECT_TYPE

@export var death_animation_duration_min:float = 1.5
@export var death_animation_duration_max:float = 4.5

# Since ships are CharacterBody3Ds and those require
# collision shapes to handle phyics of collisions,
# I'm faced with the choice of either duplicate code
# (here and in ship.gd) or duplicate collision shapes
# (as children of CharacterBody3D ships and hit box area).
# Until I resolve this, I'm going to duplicate code.
# The following 4 variables are duplicates of the code
# in hit_box_component.
# This will be populated probably only for the player
var got_hit_audio:AudioStreamPlayer
# I'll need some other system if I want different
# audio cues for taking damage or whatever.
#var hit_feedback:HitFeedback
# Anyone can damage this hitbox except for
# this ship. Currently this is used to prevent
# npcs from shooting down their own missiles.
var damage_exception:Ship
var reticle:TargetReticles


#I really like the idea of _ready functions
# searching through and equipping components
# they find as children.
# Search subtree for components. If found,
# save a reference to them and subscribe to
# their signals.
# Inspired by luislodosm's response here:
# https://forum.godotengine.org/t/easy-way-to-get-certain-type-of-children/21496/2
# And also the part of the following example
# https://www.gdquest.com/tutorial/godot/design-patterns/entity-component-pattern/
# at this part:
# "func _find_power_source_child(parent: Node) -> PowerSource:"
# This link is not saved elsewhere. It's a good
# little read, but acknowledges at the bottom
# that it's best for simulation-type games.
func _ready() -> void:
	# Search through children for various components
	# and save a reference to them.
	for child in get_children():
		if child is AimAssist:
			aim_assist = child
		elif child is BurningTrail:
			burning_trail = child
		elif child is CameraGroup:
			camera_group = child
		elif child is CharacterBodyControlParent and !disable_for_testing:
			controller = child
			# Pass export var values to controller
			if impulse_std != -1.0:
				controller.impulse_std = impulse_std
			if impulse_accel != -1.0:
				controller.impulse_accel = impulse_accel
		elif child is EngineAV:
			engineAV = child
		elif child is HealthComponent:
			health_component = child
			# Connect signals with code
			health_component.health_lost.connect(_on_health_component_health_lost)
			health_component.died.connect(_on_health_component_died)
		elif child is MissileLockGroup:
			missile_lock = child
		elif child is WeaponHandler:
			weapon_handler = child
		# The following are all from hit_box_component
		elif child is AudioStreamPlayer:
			got_hit_audio = child
		#elif child is HitFeedback:
			#hit_feedback = child
		elif child is TargetReticles:
			reticle = child
		# Remove turrets if we're just testing
		elif child is TurretGroup and disable_for_testing:
			child.queue_free()
		# Remove hangar if we're just testing
		elif child is Hangar and disable_for_testing:
			child.queue_free()


func _physics_process(delta):
	if controller:
		# Move and turn
		controller.move_and_turn(self, delta)
		# Select target
		controller.select_target(self)
		# Handle shooting of guns and missiles
		controller.shoot(self, delta)
		# Miscellaneous action (for now just switch weapon)
		controller.misc_actions(self)


func get_current_gun() -> Gun:
	if weapon_handler:
		return weapon_handler.current_weapon
	elif missile_lock:
		return missile_lock.missile_launcher
	else:
		return null


func _on_health_component_health_lost() -> void:
	# Communicate damage to the controller.
	# This will let npcs take evasive action.
	if controller:
		controller.took_damage()
	# Trail smoke and sparks when damaged
	if health_component and burning_trail:
		burning_trail.display_damage(health_component.get_percent_health())


func _on_health_component_died() -> void:
	# Disconnect the camera group
	if camera_group:
		camera_group.reparent(get_parent())
	# Explode
	VfxManager.play_with_transform(deathExplosion, global_position, transform)
	# Tell controller to enter death animation state
	# which should be some sort of chaotic tumble
	if controller:
		controller.enter_death_animation()
	# Delete targeting reticle
	if reticle:
		reticle.queue_free()
		reticle = null
	# Create and start a timer, if you haven't
	# already done so.
	# Go into death animation for this duration.
	if !death_animation_timer:
		death_animation_timer = Timer.new()
		add_child(death_animation_timer)
		death_animation_timer.timeout.connect(_on_death_timer_timeout)
		death_animation_timer.start(randf_range(
			death_animation_duration_min,
			death_animation_duration_max))


func _on_death_timer_timeout() -> void:
	destroyed.emit()
	# At the end of the timer, add an explosion
	VfxManager.play_with_transform(finalExplosion, global_position, transform)
	# Emit a signal that a ship died
	EventsBus.ship_died.emit(self)
	# Queue free this ship
	Callable(queue_free).call_deferred()


# This function is called by the ship's controller,
# inheritor of CharacterBodyControlParent, when a
# collision occurs.
# collision_severity is a percent from 0 to 1
# Full damage is dealt when the collision is
# head on at 180 degrees (pi radians). Damage falls
# off linearly from there down to zero at an angle of
# 90 degrees (pi/2) or less, but speed also factors in.
func collision_occurred(collision_severity:float) -> void:
	health_component.health -= max(1.0, max_collision_damage*collision_severity)
	# Play sound effect. Sound effect source:
	# https://pixabay.com/sound-effects/sound-design-elements-impact-sfx-ps-094-369576/
	# Creator:
	# https://pixabay.com/users/audiopapkin-14728698/
	# Edited by Neal Holtschulte using Audacity
	AudioManager.play_remote_transform(SoundEffectSetting.SOUND_EFFECT_TYPE.COLLISION_IMPACT, self)


# Projectiles ask if the cursor / mouse is centered enough to
# aim at it instead of aiming straight ahead. This code gives
# me the heeby jeebies, because it's just a wrapper for the
# camera group, which NPCs won't even have, but it's what I'm
# going with for now.
func is_mouse_near_center() -> bool:
	if is_instance_valid(camera_group):
		return camera_group.is_mouse_near_center()
	return false
func get_mouse_center_radius() -> float:
	if is_instance_valid(camera_group):
		return sqrt(camera_group.MOUSE_CENTER_RADIUS)
	return 0.0

# ALL THE FOLLOWING CODE IS duplicated from hit_box_component

func damage(amount:float, damager=null):
	# A Ship shouldn't shoot down their own missiles
	if damager and is_instance_valid(damage_exception) and damager == damage_exception:
		return
	if health_component:
		health_component.health -= amount
	#if hit_feedback:
		#hit_feedback.hit()


func add_damage_exception(s:Ship) -> void:
	damage_exception = s


# This is called when the player targets this hitbox
# component. However, in the future, I'd like it to
# be more flexible, so now I'm passing in the
# targeter so we can check if it's the player.
func set_targeted(targeter:Node3D, value:bool) -> void:
	if Global.player == targeter and reticle:
		reticle.is_targeted = value
	# In the future this should also signal to the
	# object that owns this hitbox that it is
	# being targeted


# These are called by the missile lock group when
# targeter is seeking lock on this hitbox,
# loses lock, acquires lock, or fires a missile.
func seeking_lock(_targeter:Node3D) -> void:
	pass
func lost_lock(_targeter:Node3D) -> void:
	pass
func lock_acquired(_targeter:Node3D) -> void:
	pass
func missile_inbound(_targeter:Node3D) -> void:
	pass


# Of the following, currently only _on_body_entered
# is triggering and only when the hitbox crashes
# into a body like the side of the capital ship.
# This is fine for now, but if you want more audio
# on the hitbox side, you'll also need to adjust
# the collision bitmask.
func _on_area_entered(_area: Area3D) -> void:
	if got_hit_audio:
		got_hit_audio.play()
func _on_body_entered(_body: Node3D) -> void:
	if got_hit_audio:
		got_hit_audio.play()
