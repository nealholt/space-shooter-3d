extends Node3D
class_name Turret

# movement speeds and constraints in degrees
@export var elevation_speed_deg: float = 5
@export var rotation_speed_deg: float = 5
@export var min_elevation_deg: float = 0
@export var max_elevation_deg: float = 60

# movement speeds and constraints in radians
@onready var elevation_speed: float = deg_to_rad(elevation_speed_deg)
@onready var rotation_speed: float = deg_to_rad(rotation_speed_deg)
@onready var min_elevation: float = deg_to_rad(min_elevation_deg)
@onready var max_elevation: float = deg_to_rad(max_elevation_deg)

var target_pos: Vector3 = Vector3.ZERO

# states
var active: bool = true

var aim_assist:AimAssist
var health_component:HealthComponent
var hit_feedback:HitFeedback
var target_selector:TargetSelector
var turret_motion:TurretMotionComponent

#TODO
@onready var gun: BurstGun = %BurstGun
@onready var gun_2: BurstGun = %BurstGun2
@onready var head: Node3D = $TurretModel/Body/Head
@onready var body: Node3D = $TurretModel/Body

# If angle to target is less than this number of degrees, then shoot
@export var angle_to_shoot_deg : float = 5
var angle_to_shoot : float = deg_to_rad(angle_to_shoot_deg)

var orientation_data:TargetOrientationData


func _ready() -> void:
	# test if got head and body
	if head == null or body == null:
		active = false
	orientation_data = TargetOrientationData.new()
	# Search through children for various components
	# and save a reference to them.
	for child in get_children():
		if child is AimAssist:
			aim_assist = child
		elif child is HealthComponent:
			health_component = child
			# Connect signals with code
			health_component.health_lost.connect(_on_health_component_health_lost)
			health_component.died.connect(_on_health_component_died)
		elif child is HitFeedback:
			hit_feedback = child
		elif child is TargetSelector:
			target_selector = child
		elif child is TurretMotionComponent:
			turret_motion = child


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Get target from the target selector
	var target = target_selector.get_target(self)
	# Update profile.orientation_data
	if target:
		orientation_data.update_data(global_position,
			gun.bullet_speed, target, global_transform.basis)
	
	# if active and with target, then move the turret
	if active and turret_motion and orientation_data.target_pos != Vector3.ZERO:
		turret_motion.rotate_and_elevate(body, head, delta, orientation_data.target_pos)
	
	# Shoot if within angle limit
	if Global.get_angle_to_target(head.global_position, orientation_data.target_pos, head.global_transform.basis.z) < angle_to_shoot:
		#TODO re-the-fuck-think this next bit
		# You need to pass in some "shooter" with the right collision
		# masks and layers set. The hitbox was the best option.
		gun.shoot($HitBoxComponent, orientation_data.target)
		gun_2.shoot($HitBoxComponent, orientation_data.target)


func _on_health_component_health_lost() -> void:
	if hit_feedback:
		hit_feedback.hit()


func _on_health_component_died() -> void:
	queue_free()
