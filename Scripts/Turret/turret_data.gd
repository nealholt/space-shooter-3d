class_name TurretData extends Node3D

# Just a struct to attach to Node3D turret hardpoints
# so that the turret that gets put in that spot can
# be properly parameterized.

# movement speeds and constraints in degrees
@export var elevation_speed_deg: float = 5
@export var rotation_speed_deg: float = 5
@export var min_elevation_deg: float = 0
@export var max_elevation_deg: float = 60

@export var angle_to_shoot_deg : float = 5

# Not yet implemented
@export var use_aim_assist:bool = false
@export var angle_assist_limit:float = 3.0 # degrees
