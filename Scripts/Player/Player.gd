extends CharacterBody3D

@onready var camera: Camera3D = $CameraGroup/Body/Head/FirstPersonCamera
@onready var camera_group: Node3D = $CameraGroup

@onready var got_hit_audio: AudioStreamPlayer3D = $Sounds/GotHitAudio
# The health_component is currently only used by the HUD in the main scene
@onready var health_component: HealthComponent = $HealthComponent
@onready var missile_lock: MissileLock = $MissileLockGroup
# Can achieve and maintain missile lock if target is
# within plus of minus of this angle from center.
var missile_lock_max_angle:float = deg_to_rad(35)

# Currently targeted ship or capital ship component
var targeted:Node3D

# Connect a controller
@export var controller : CharacterBodyControlParent


func _ready():
	# Tell the global script who the player is
	Global.player = self


func _physics_process(delta):
	# Move and turn
	controller.move_and_turn(self,delta)
	
	# Trigger pulled. Try to shoot.
	if $WeaponHandler.is_automatic():
		if Input.is_action_pressed("shoot"):
			$WeaponHandler.shoot(self, targeted)
	else: # Semiautomatic
		if Input.is_action_just_pressed("shoot"):
			$WeaponHandler.shoot(self, targeted)
	
	# Target most centered enemy and begin missile lock
	if Input.is_action_just_pressed("right_shoulder"):
		# Unset previous target if any
		if is_instance_valid(targeted):
			targeted.set_targeted(false)
			targeted = null
		# Target most central red team fighter
		targeted = Global.get_center_most_from_group("red team",self)
		if is_instance_valid(targeted):
			targeted.set_targeted(true)
			# Create missile reticle and put it on the screen
			missile_lock.start_seeking(targeted)
	# Fire missile if lock is acquired
	if Input.is_action_just_released("right_shoulder"):
		if missile_lock.locked:
			shoot_missile(missile_lock.launch())
		missile_lock.stop_seeking()
	# Stop seeking if target no longer valid or out of range or offscreen
	if missile_lock.seeking and \
	(!is_instance_valid(targeted) or \
	global_position.distance_squared_to(targeted.global_position) > missile_lock.missile_range_sqd \
	or Global.get_angle_to_target(global_position, targeted.global_position, -global_basis.z) > missile_lock_max_angle):
		missile_lock.stop_seeking()


# quick_launch is true if the player released the missile
# within a short interval of acquiring lock, in which case
# the missile should be stronger, faster, or otherwise
# better in some way.
func shoot_missile(quick_launch:bool) -> void:
	# Send a missile after the target
	$MissileLauncher.shoot(self, targeted, quick_launch)


# Since we're listening for the hitbox getting hit, this doesn't
# actually make a noise based on damage and it isn't.
# For ex, this makes a noise upon collision with an enemy,
# but that doesn't actually do damage.
func _on_hit_box_component_area_entered(_area: Area3D) -> void:
	#print('hitbox area entered')
	got_hit_audio.play()
func _on_hit_box_component_body_entered(_body: Node3D) -> void:
	#print('hitbox body entered')
	got_hit_audio.play()
# THIS is the noise that gets played when we take damage
func _on_health_component_health_lost() -> void:
	got_hit_audio.play()

func _on_health_component_died() -> void:
	# Load main scene if player dies
	Global.main_scene.to_main_menu()
