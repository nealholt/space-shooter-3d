extends Node3D

# The following is loosely based on code from here:
# https://github.com/IndieQuest/ModularTurret/tree/master/src
# https://www.youtube.com/watch?v=4IS9zIVCDKc&ab_channel=IndieQuest
# but modified by Neal Holtschulte in 2024 because
# 1. That code didn't work for me and 
# 2. it was designed to only work when the turret
# was parallel to the ground.
# This was a life saver:
# https://math.stackexchange.com/questions/728481/3d-projection-onto-a-plane

 # TESTING
@onready var projection_indicator: Node3D = $"../projection_indicator"
@onready var elevation_projection: Node3D = $"../elevation_projection"

# movement
@export var elevation_speed_deg: float = 5
@export var rotation_speed_deg: float = 5
# constraints
@export var min_elevation_deg: float = 0
@export var max_elevation_deg: float = 60

# parts
@export var body: Node3D # Component to be rotated
@export var head: Node3D # Component to be elevated
@export var target: Node3D
# movement
@onready var elevation_speed: float = deg_to_rad(elevation_speed_deg)
@onready var rotation_speed: float = deg_to_rad(rotation_speed_deg)
@onready var min_elevation: float = deg_to_rad(min_elevation_deg)
@onready var max_elevation: float = deg_to_rad(max_elevation_deg)
# target calculation
var current_target: Vector3
# states
var active: bool = true


func _ready() -> void:
	# test if got head and body
	if head == null or body == null:
		active = false
	# test if got valid target
	if target == null: # or not "linear_velocity" in target:
		active = false


func _physics_process(delta: float) -> void:
	# if not active do nothing
	if not active:
		return
	# update target location
	current_target = target.global_position
	# move
	rotate_and_elevate(delta)


func rotate_and_elevate(delta: float) -> void:
	# Project the target onto the XZ plane of the turret.
	# This works even if the turret is rotated!
	# Project current_target onto the plane perpendicular to body.global_basis.y
	# https://math.stackexchange.com/questions/728481/3d-projection-onto-a-plane
	# plane_norm is the vector our plane is perpendicular to
	var plane_norm:Vector3 = body.global_basis.y
	# projected is the vector indicating how far above/below
	# the target point is from our plane
	var projected:Vector3 = (current_target.dot(plane_norm) / plane_norm.dot(plane_norm)) * plane_norm
	# by subtracting projected from target, we get the projected point.
	# This is the point to rotate the turret toward
	var rotation_targ:Vector3 = current_target - projected
	projection_indicator.global_position = rotation_targ
	
	# Get the desired rotation
	# Get the angle to projected point
	var y_angle:float = body.global_basis.z.angle_to(rotation_targ)
	# Transform target to body local space. This is useful to
	# know if we should rotate left or right because angle_to
	# always returns a positive value.
	var local_target:Vector3 = body.to_local(target.global_position)
	
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
	projected = (current_target.dot(plane_norm) / plane_norm.dot(plane_norm)) * plane_norm
	# by subtracting projected from target, we get the projected point.
	# This is the point to rotate the turret toward
	var elevation_targ:Vector3 = current_target - projected
	elevation_projection.global_position = elevation_targ
	
	# Get the desired rotation
	# Get the angle to projected point
	var x_angle:float = head.global_basis.z.angle_to(elevation_targ)
	
	# Elevate toward it
	# One more negative sign because pitching up is negative
	var elevation_sign:float = -sign(head.to_local(target.global_position).y)
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
