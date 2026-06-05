class_name TurretData extends Node3D

# Just a struct to attach to Node3D turret hardpoints
# so that the turret that gets put in that spot can
# be properly parameterized.

# movement speeds and constraints. You enter the number
# in degrees and it comes out in radians.
# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html#adding-suffixes-and-handling-degrees-radians
@export_range(0, 720, 0.1, "radians_as_degrees") var elevation_speed: float = deg_to_rad(5.0)
@export_range(0, 720, 0.1, "radians_as_degrees") var rotation_speed: float = deg_to_rad(5.0)
@export_range(-90, 90, 0.1, "radians_as_degrees") var min_elevation: float = 0.0
@export_range(0, 90, 0.1, "radians_as_degrees") var max_elevation: float = deg_to_rad(60.0)

@export_range(0, 90, 0.1, "radians_as_degrees") var angle_to_shoot: float = deg_to_rad(5.0)

@export var use_aim_assist:bool = false
@export var angle_assist_limit:float = 3.0 # degrees

# Whether or not to target capital ships first
@export var prefer_capital_ships:bool = false

@export var gun:GunStats
