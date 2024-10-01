extends CharacterBody3D

@onready var camera: Camera3D = $CameraGroup/Body/Head/FirstPersonCamera
@onready var camera_group: Node3D = $CameraGroup

@onready var got_hit_audio: AudioStreamPlayer3D = $Sounds/GotHitAudio
# The health_component is currently only used by the HUD in the main scene
@onready var health_component: HealthComponent = $HealthComponent
@onready var missile_lock: MissileLock = $MissileLockGroup

# Currently targeted ship or capital ship component
var targeted:Node3D

# Connect a controller
@export var controller : CharacterBodyControlParent


func _ready():
	# Tell the global script who the player is
	Global.player = self


func _physics_process(delta):
	controller.move_and_turn(self,delta)
	
	# Check for D-Pad input to change pov
	change_pov()
	
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
		targeted = Global.get_center_most_from_group("red team",camera)
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
	or !camera.is_position_in_frustum(targeted.global_position)):
		missile_lock.stop_seeking()



# quick_launch is true if the player released the missile
# within a short interval of acquiring lock, in which case
# the missile should be stronger, faster, or otherwise
# better in some way.
func shoot_missile(quick_launch:bool) -> void:
	# Send a missile after the target
	$MissileLauncher.shoot(self, targeted, quick_launch)


func change_pov() -> void:
	# Right thumb stick pressed in. Switch to first person
	# and as long as right stick is held in, look at
	# current target.
	if Input.is_action_just_pressed("POV_standard"):
		camera_group.first_person()
		camera_group.turn_on_look()
	# Target view. Look towards the target, but from the far
	# side of the player so the player can turn to face target.
	# D-Pad up
	elif Input.is_action_just_pressed("POV_target_look"):
		camera_group.target_camera()
	# Target close up. Launch the camera out toward the target.
	# D-Pad right
	elif Input.is_action_just_pressed("POV_target_closeup"):
		#camera.top_level = true # Don't inherit parent's transform
		camera_group.target_closeup_camera()
	# Fixed underslung rear view showing the belly and tail
	# of player's ship looking backwards.
	# D-Pad down
	elif Input.is_action_just_pressed("POV_rear"):
		camera_group.rear_camera()
	# Cinematic fly-by view. Launch the camera out of ahead
	# of the player and watch the player fly be.
	# D-Pad left
	elif Input.is_action_just_pressed("POV_flyby"):
		camera_group.flyby_camera()
	# Turn off target look when right thumbstick is released
	elif Input.is_action_just_released("POV_standard"):
		camera_group.look_at_target = false


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
