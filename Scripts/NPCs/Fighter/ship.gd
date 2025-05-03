class_name Ship extends CharacterBody3D

signal destroyed

var aim_assist:AimAssist
var burning_trail:BurningTrail # This is a visual effect
var controller:CharacterBodyControlParent
var engineAV:EngineAV
var health_component:HealthComponent
var missile_lock:MissileLockGroup
var weapon_handler:WeaponHandler

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
var hit_feedback:HitFeedback
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
		elif child is CharacterBodyControlParent:
			controller = child
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
		elif child is HitFeedback:
			hit_feedback = child
		elif child is TargetReticles:
			reticle = child


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
	# Explode
	VfxManager.play_with_transform(deathExplosion, global_position, transform)
	# Tell controller to enter death animation state
	# which should be some sort of chaotic tumble
	if controller:
		controller.enter_death_animation()
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
	# At the end of the timer, add an explosion to
	# main_3d and properly queue free this ship
	VfxManager.play_with_transform(finalExplosion, global_position, transform)
	# The controller will handle cleaning up.
	# NPCs will be queue freed. Players will be
	# sent back to the main menu.
	if controller:
		controller.died(self)
	else:
		# Just in case there is no controller
		Callable(queue_free).call_deferred()



# ALL THE FOLLOWING CODE IS duplicated from hit_box_component

func damage(amount:float, damager=null):
	# A Ship shouldn't shoot down their own missiles
	if damager and is_instance_valid(damage_exception) and damager == damage_exception:
		return
	if health_component:
		health_component.health -= amount
	if hit_feedback:
		hit_feedback.hit()


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
