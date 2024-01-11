extends Node3D
class_name Turret

# Source: 
# https://github.com/IndieQuest/ModularTurret/tree/master/src
# Source: 
# https://www.youtube.com/watch?v=4IS9zIVCDKc&ab_channel=IndieQuest
# Converted to Godot 4 and further commented and modified
# by Neal Holtschulte in 2024

# movement
@export var elevation_speed_deg: float = 45
@export var rotation_speed_deg: float = 90
# bullets
@export var muzzle_velocity: float = 50
# constraints
@export var min_elevation: float = -10
@export var max_elevation: float = 60

# parts
@export var body: Node3D
@export var head: Node3D
@export var target: Node3D
# movement
@onready var elevation_speed: float = deg_to_rad(elevation_speed_deg)
@onready var rotation_speed: float = deg_to_rad(rotation_speed_deg)
# target calculation
var current_target: Vector3
# states
var active: bool = true



################################
# OVERRIDE FUNCTIONS
################################
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
	_update_target_location()
	# move
	_rotate(delta)
	_elevate(delta)


################################
# MAIN FUNCTIONS
################################
func _update_target_location() -> void:
	current_target = target.global_position


func _rotate(delta: float) -> void:
	# get displacment (amount we want to rotate)
	var y_target = _get_local_y()
	# calculate step size and direction. If we need to rotate
	# less than out max rotation, then snap to desired angle
	# using the min function
	var final_y = sign(y_target) * min(rotation_speed * delta, abs(y_target))
	# rotate body
	body.rotate_y(final_y)


func _elevate(delta: float) -> void:
	# get displacment
	var x_target = _get_global_x()
	var x_diff = x_target - head.global_transform.basis.get_euler().x
	var final_x = sign(x_diff) * min(elevation_speed * delta, abs(x_diff))
	# elevate head
	head.rotate_x(final_x)
	# clamp
	head.rotation_degrees.x = clamp(
		head.rotation_degrees.x,
		min_elevation, max_elevation
	)


################################
# HELPER FUNCTIONS
################################
func _get_local_y() -> float:
	# Transform target to head local space
	var local_target = head.to_local(current_target)
	# Cast target location to x,z plane and get just the
	# y rotation angle to the target
	var y_angle = Vector3.FORWARD.angle_to(local_target * Vector3(1, 0, 1))
	# multiply this y angle by negative the target's local x sign
	# so we know which way we should be rotating.
	return y_angle * -sign(local_target.x)


func _get_global_x() -> float:
	var local_target = current_target - head.global_position
	return (local_target * Vector3(1, 0, 1)).angle_to(local_target) * sign(local_target.y)

