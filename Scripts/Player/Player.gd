extends CharacterBody3D

@onready var camera: Camera3D = $CameraGroup/FirstPersonCamera
@onready var camera_group: Node3D = $CameraGroup

@onready var got_hit_audio: AudioStreamPlayer3D = $Sounds/GotHitAudio
@onready var near_miss_audio: AudioStreamPlayer3D = $Sounds/NearMissAudio
# The health_component is currently only used by the HUD in the main scene
@onready var health_component: HealthComponent = $HealthComponent
@onready var missile_lock: MissileLock = $MissileLockGroup

# Currently targeted ship or capital ship component
var targeted:Node3D

# For the following I have been using "ballistic_move3" for a
# while. It is is the ONLY one with move_and_collide
# implemented. You WILL need to add that in if you ever
# switch movement schemes.
var flight_mode: int = 2
var ballistic_move1:BallisticMovement1 = BallisticMovement1.new()
var ballistic_move2:BallisticMovement2 = BallisticMovement2.new()
var ballistic_move3:BallisticMovement3 = BallisticMovement3.new()
var flight_move1:FlightMovement1 = FlightMovement1.new()
var fps_move1:FPSMovement1 = FPSMovement1.new()


func _ready():
	# Tell the global script who the player is
	Global.player = self


func _physics_process(delta):
	if flight_mode == 0:
		ballistic_move1.move(self,delta)
	elif flight_mode == 1:
		ballistic_move2.move(self,delta)
	elif flight_mode == 2:
		ballistic_move3.move(self,delta)
	elif flight_mode == 3:
		flight_move1.move(self,delta)
	else:
		fps_move1.move(self,delta)

	# x to change flight mode
	if Input.is_action_just_pressed("x_button"):
		flight_mode = (flight_mode+1) % 5
		print('Entering flight mode %s' % flight_mode)
	
	# Check for D-Pad input to change pov
	change_pov()
	
	# Trigger pulled. Try to shoot.
	if Input.is_action_just_pressed("right_trigger"):
		var bullet_data:ShootData = ShootData.new()
		bullet_data.shooter = self
		var did_shoot:bool = $GunGroup/Gun.shoot(bullet_data)
		if did_shoot:
			$GunGroup/GatlingGun/AnimationPlayer.play("rotate")
			$GunGroup/MuzzleFlash.restart()
	# Target most centered enemy and begin missile lock
	if Input.is_action_just_pressed("right_shoulder"):
		# Unset previous target if any
		if is_instance_valid(targeted):
			targeted.set_targeted(false)
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
	var bullet_data:ShootData = ShootData.new()
	# Identify target with smallest angle to
	bullet_data.target = targeted
	bullet_data.shooter = self
	bullet_data.super_powered = quick_launch
	$MissileLauncher.shoot(bullet_data)


func change_pov() -> void:
	# Right thumb stick pressed in
	if Input.is_action_just_pressed("POV_standard"):
		camera_group.first_person()
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

func _on_near_miss_detector_area_exited(area: Area3D) -> void:
	# Play audio for enemy bullet near misses!
	if area is Projectile:
		near_miss_audio.global_position = area.global_position
		near_miss_audio.play()

func _on_health_component_died() -> void:
	# Load main scene if player dies
	Global.main_scene.to_main_menu()
