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

var aim_assist:AimAssist
var guns: Array
var health_component:HealthComponent
var target_selector:TargetSelector
var turret_motion:TurretMotionComponent

# Turret components necessary for rotation toward target
var head: Node3D
var body: Node3D
var orientation_data:TargetOrientationData

# If angle to target is less than this number of degrees, then shoot
@export var angle_to_shoot_deg : float = 5
var angle_to_shoot : float = deg_to_rad(angle_to_shoot_deg)


func _ready() -> void:
	# Setup head and body
	var nodes_in_group_head = Global.get_group_nodes_on_branch("turret head", self)
	var nodes_in_group_body = Global.get_group_nodes_on_branch("turret body", self)
	# Sanity checks
	if nodes_in_group_head.size() != 1:
		printerr("More than one turret head node detected in turret.gd")
		get_tree().quit()
	if nodes_in_group_body.size() != 1:
		printerr("More than one turret body node detected in turret.gd")
		get_tree().quit()
	head = nodes_in_group_head[0]
	body = nodes_in_group_body[0]
	
	# Setup orientation data
	orientation_data = TargetOrientationData.new()
	
	# Search through children for various components
	# and save a reference to them.
	for child in get_children():
		if child is AimAssist:
			aim_assist = child
		elif child is Gun:
			guns.append(child)
		elif child is HealthComponent:
			health_component = child
			# Connect signals with code
			health_component.health_lost.connect(_on_health_component_health_lost)
			health_component.died.connect(_on_health_component_died)
		elif child is TargetSelector:
			target_selector = child
		elif child is TurretMotionComponent:
			turret_motion = child
	
	# Position all the guns at all the hardpoints
	var gun_hardpoints = Global.get_group_nodes_on_branch("gun hardpoint", self)
	# Sanity check
	if gun_hardpoints.size() != guns.size():
		printerr("Mismatch between number of guns %d and number of hardpoints %d" % [guns.size(), gun_hardpoints.size()])
		get_tree().quit()
	for i in range(guns.size()):
		guns[i].reparent(gun_hardpoints[i], false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Get target from the target selector
	var target = target_selector.get_target(self)
	# Update profile.orientation_data
	if target:
		orientation_data.update_data(global_position,
			guns[0].bullet_speed, target, global_transform.basis)
	
	# if components are installed, then move the turret
	if turret_motion and orientation_data.target_pos != Vector3.ZERO:
		turret_motion.rotate_and_elevate(body, head, delta, orientation_data.target_pos)
	
	# Shoot if within angle limit
	if is_instance_valid(orientation_data.target) and Global.get_angle_to_target(head.global_position, orientation_data.target_pos, head.global_transform.basis.z) < angle_to_shoot:
		for gun in guns:
			gun.shoot(self, orientation_data.target)


func _on_health_component_health_lost() -> void:
	pass # nothing for now


func _on_health_component_died() -> void:
	queue_free()
