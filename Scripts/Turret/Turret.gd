extends Node3D

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

@onready var target_selector: Node = $TurretModel/Body/Head/TargetSelector
@onready var gun: Node3D = %Gun
@onready var gun_2: Node3D = %Gun2
@onready var head: Node3D = $TurretModel/Body/Head
@onready var body: Node3D = $TurretModel/Body
@onready var hit_feedback: Node3D = $HitFeedback

# If angle to target is less than this number of degrees, then shoot
@export var angle_to_shoot_deg : float = 5
var angle_to_shoot : float = deg_to_rad(angle_to_shoot_deg)


func _ready() -> void:
	# test if got head and body
	if head == null or body == null:
		active = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Update the turret_model's position to target
	target_pos = target_selector.get_lead(gun.bullet_speed)
	
	# if active and with target, then move the turret
	if active and target_pos != Vector3.ZERO:
		rotate_and_elevate(delta)
	
	# Shoot if within angle limit
	#print()
	#print(head.global_position)
	#print(round(target_pos))
	#print(round(head.global_transform.basis.z))
	#print(round(rad_to_deg(Global.get_angle_to_target(head.global_position,target_pos, head.global_transform.basis.z))))
	#print(angle_to_shoot)
	#print(round(rad_to_deg(Global.get_angle_to_target(body.global_position,target_pos, body.global_transform.basis.z))))
	#print(round(rad_to_deg(body.global_basis.z.angle_to(target_pos))))
	if Global.get_angle_to_target(head.global_position,target_pos, head.global_transform.basis.z) < angle_to_shoot:
		var bullet_data:ShootData = ShootData.new()
		# You need to pass in some "shooter" with the right collision
		# masks and layers set. The hitbox was the best option.
		#print('shooting')
		bullet_data.shooter = $HitBoxComponent
		gun.shoot(bullet_data)
		gun_2.shoot(bullet_data)


func _on_health_component_health_lost() -> void:
	hit_feedback.hit()


func _on_health_component_died() -> void:
	queue_free()


# The following is loosely based on code from here:
# https://github.com/IndieQuest/ModularTurret/tree/master/src
# https://www.youtube.com/watch?v=4IS9zIVCDKc&ab_channel=IndieQuest
# but modified by Neal Holtschulte in 2024 because
# 1. That code didn't work for me and 
# 2. it was designed to only work when the turret
# was parallel to the ground.
# This was a life saver:
# https://math.stackexchange.com/questions/728481/3d-projection-onto-a-plane
func rotate_and_elevate(delta: float) -> void:
	# Project the target onto the XZ plane of the turret.
	# This works even if the turret is rotated!
	# Project current_target onto the plane perpendicular to body.global_basis.y
	# https://math.stackexchange.com/questions/728481/3d-projection-onto-a-plane
	# plane_norm is the vector our plane is perpendicular to
	var plane_norm:Vector3 = body.global_basis.y
	# projected is the vector indicating how far above/below
	# the target point is from our plane
	var projected:Vector3 = (target_pos.dot(plane_norm) / plane_norm.dot(plane_norm)) * plane_norm
	# by subtracting projected from target, we get the projected point.
	# This is the point to rotate the turret toward
	var rotation_targ:Vector3 = target_pos - projected
	
	# Get the desired rotation
	# Get the angle to projected point
	var y_angle:float = body.global_basis.z.angle_to(rotation_targ)
	# Transform target to body local space. This is useful to
	# know if we should rotate left or right because angle_to
	# always returns a positive value.
	var local_target:Vector3 = body.to_local(target_pos)
	
	# Rotate toward it
	# Calculate step size and direction. If we need to rotate
	# less than out max rotation, then snap to desired angle
	# using the min function
	var final_y:float = sign(local_target.x) * min(rotation_speed * delta, y_angle)
	# rotate body
	body.rotate_y(final_y)
	
	# Rotation is complete, not we elevate
	# Project the target onto the ZY plane of the turret.
	# This works even if the turret is rotated!
	# Project current_target onto the plane perpendicular to head.global_basis.y
	# https://math.stackexchange.com/questions/728481/3d-projection-onto-a-plane
	# plane_norm is the vector our plane is perpendicular to
	plane_norm = head.global_basis.x
	# projected is the vector indicating how far above/below
	# the target point is from our plane
	projected = (target_pos.dot(plane_norm) / plane_norm.dot(plane_norm)) * plane_norm
	# by subtracting projected from target, we get the projected point.
	# This is the point to rotate the turret toward
	var elevation_targ:Vector3 = target_pos - projected
	
	# Get the desired rotation
	# Get the angle to projected point
	var x_angle:float = head.global_basis.z.angle_to(elevation_targ)
	
	# Elevate toward it
	# One more negative sign because pitching up is negative
	var elevation_sign:float = -sign(head.to_local(target_pos).y)
	var final_x:float = elevation_sign * min(elevation_speed * delta, x_angle)
	#print(rad_to_deg(final_x))
	# elevate head
	head.rotate_x(final_x)
	# Clamp elevation within limits
	# Reverse and negate max and min because up is negative and
	# down is positive
	head.rotation.x = clamp(
		head.rotation.x,
		-max_elevation, min_elevation
	)

