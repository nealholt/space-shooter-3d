class_name ControllerStats extends Resource

# Amount of forward impulse, pitch, roll, and yaw
# under standard thrust.
@export var impulse_std := 60.0
@export var pitch_std := 1.8
@export var roll_std := 0.6
@export var yaw_std := 0.6
# Amount to lerp the impulse and turning.
# 0.01 is incredibly sluggish and floaty
# Even 0.1 is quite responsive, but a bit gradual
# 1.0 is no lerp at all. aka immediate snap to target value.
# but these values are relevant AFTER multiplying by delta
# so typically 1/60th of this value. I say again
# around 60.0 is 1.0 because it's multiplied by delta.
@export var impulse_lerp := 1.0 # Used to be 1 for player and 10 for NPCs
# turning_lerp is the lerp used for changing pitch,
# roll, and yaw.
@export var turning_lerp := 3.5


# TODO The following is currently only used by the
# player, not the NPCs.

# Amount of forward impulse, pitch, roll, and yaw
# under acceleration. Typically maneuverability is
# reduced under acceleration.
@export var impulse_accel := 200.0
@export var pitch_accel := 0.6
@export var roll_accel := 0.6
@export var yaw_accel := 0.3
