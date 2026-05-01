class_name ControllerStats extends Resource

# Amount of forward impulse, pitch, roll, and yaw
# under standard thrust.
@export var impulse_std := 60.0
@export var pitch_std := 1.8
@export var roll_std := 0.6
@export var yaw_std := 0.6

# Amount of forward impulse, pitch, roll, and yaw
# under acceleration. Typically maneuverability is
# reduced under acceleration.
# TODO The following is currently only used by the
# player, not the NPCs.
@export var impulse_accel := 200.0
@export var pitch_accel := 0.6
@export var roll_accel := 0.6
@export var yaw_accel := 0.3
