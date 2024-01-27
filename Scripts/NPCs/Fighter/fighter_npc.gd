extends CharacterBody3D
class_name FighterNPC

signal destroyed

@onready var target_selector: Node = $TargetSelector

# Modifiers for movement amount
@export var speed: float = 40.0*60.0 # 40.0 meters per second
@export var pitch_amt: float = 0.8
@export var roll_amt: float = 0.8
@export var yaw_amt: float = 0.1

# acceleration is lerp strength for speed
# for now lerp_str is lerp strength for any turning
@export var acceleration: float = 10.0
@export var lerp_str: float = 3.0

# Parameters for attack pass movement
@export var too_close_sqd: float = 30.0**2
@export var too_far_sqd: float = 200.0**2

# Within this angle of the target, the enemy
# will start shooting
var shooting_angle := deg_to_rad(10.0) # degrees (immediately converted to radians)
# Within this angle of the target, the enemy
# will snap to face the target
var snap_to_angle := deg_to_rad(8.0) # degrees (immediately converted to radians)

# Parameters for lerping the amount of roll, pitch,
# yaw, and speed.
var pitch_str: float = 0.0
var roll_str: float = 0.0
var yaw_str: float = 0.0
var current_speed: float = 0.0

# Sound to be played on death. Self-freeing.
@export var pop_player: PackedScene
@onready var profile: MovementProfile = $StateMachine/MovementProfile

# Keep track of target position and distance to target
# and update these every frame
var target_pos:Vector3
var distance_to_target_sqd:float


func _physics_process(delta):
	# Update position (ahead of the target if its moving)
	# and distance to target. This will automatically
	# update select a new target if current target has
	# been destroyed.
	target_pos = target_selector.get_lead($Gun.bullet_speed)
	distance_to_target_sqd = target_selector.get_distance_to_target()
	
	# Move
	# snap to given transform or lerp to desired turning amount
	if profile.new_transform:
		transform = profile.new_transform
	else:
		# Lerp toward desired settings
		pitch_str = lerp(pitch_str, profile.goal_pitch * pitch_amt, lerp_str*delta)
		roll_str = lerp(roll_str, profile.goal_roll * roll_amt, lerp_str*delta)
		yaw_str = lerp(yaw_str, profile.goal_yaw * yaw_amt, lerp_str*delta)
		current_speed = lerp(current_speed, profile.goal_speed * speed, acceleration*delta)
		# Pitch
		transform.basis = transform.basis.rotated(transform.basis.x, pitch_str * delta)
		# Roll
		transform.basis = transform.basis.rotated(transform.basis.z, roll_str * delta)
		# Yaw
		transform.basis = transform.basis.rotated(transform.basis.y, yaw_str * delta)
	# Move straight ahead
	velocity = -transform.basis.z * current_speed * delta
	move_and_slide()
	# Move, collide, and bounce off
	# Resources used:
	# https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html
	#var collision :KinematicCollision3D = move_and_collide(velocity * delta) #NEW WAY
	#if collision:
	#	velocity = velocity.bounce(collision.get_normal())
	
	# Shoot at player if within distance and angle
	if distance_to_target_sqd < $Gun.range_sqd && Global.get_angle_to_target(self.global_position,target_pos, -global_transform.basis.z) < shooting_angle:
		var bullet_data:ShootData = ShootData.new()
		bullet_data.shooter = self
		$Gun.shoot(bullet_data)


func _on_health_component_health_lost() -> void:
	# Force a switch into evasion state
	$StateMachine.go_evasive()
	# Play hit sound


func _on_health_component_died() -> void:
	destroyed.emit()
	# Create self-freeing audio to play pop sound
	var on_death_sound = pop_player.instantiate()
	get_tree().get_root().add_child(on_death_sound)
	on_death_sound.play_then_delete(global_position)
	# Wait until the end of the frame to execute queue_free
	Callable(queue_free).call_deferred()


# This function is dubplicated in TurretComplete script
func set_targeted(value:bool) -> void:
	$TargetReticles.is_targeted = value