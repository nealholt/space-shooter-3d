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

@onready var target_selector: Node = $TargetSelector
@onready var gun: BurstGun = %BurstGun
@onready var gun_2: BurstGun = %BurstGun2
@onready var head: Node3D = $TurretModel/Body/Head
@onready var body: Node3D = $TurretModel/Body
@onready var hit_feedback: Node3D = $HitFeedback

# If angle to target is less than this number of degrees, then shoot
@export var angle_to_shoot_deg : float = 5
var angle_to_shoot : float = deg_to_rad(angle_to_shoot_deg)

var orientation_data:TargetOrientationData


func _ready() -> void:
	# test if got head and body
	if head == null or body == null:
		active = false
	orientation_data = TargetOrientationData.new()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Get target from the target selector
	var target = target_selector.get_target(self)
	# Update profile.orientation_data
	if target:
		orientation_data.update_data(global_position,
			gun.bullet_speed, target, global_transform.basis)
	
	# if active and with target, then move the turret
	if active and orientation_data.target_pos != Vector3.ZERO:
		$turret_motion_component.rotate_and_elevate(body, head, delta, orientation_data.target_pos)
	
	# Shoot if within angle limit
	#print()
	#print(head.global_position)
	#print(round(target_pos))
	#print(round(head.global_transform.basis.z))
	#print(round(rad_to_deg(Global.get_angle_to_target(head.global_position,target_pos, head.global_transform.basis.z))))
	#print(angle_to_shoot)
	#print(round(rad_to_deg(Global.get_angle_to_target(body.global_position,target_pos, body.global_transform.basis.z))))
	#print(round(rad_to_deg(body.global_basis.z.angle_to(target_pos))))
	if Global.get_angle_to_target(head.global_position, orientation_data.target_pos, head.global_transform.basis.z) < angle_to_shoot:
		# You need to pass in some "shooter" with the right collision
		# masks and layers set. The hitbox was the best option.
		gun.shoot($HitBoxComponent, orientation_data.target)
		gun_2.shoot($HitBoxComponent, orientation_data.target)


func _on_health_component_health_lost() -> void:
	hit_feedback.hit()


func _on_health_component_died() -> void:
	queue_free()
