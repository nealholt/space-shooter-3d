class_name ControllerStats extends Resource

# More info on export_range here:
# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html

# Amount of forward impulse, pitch, roll, and yaw
# under standard thrust.
@export_range(0, 500, 1.0, "or_greater") var impulse := 60.0
@export_range(0, 4, 0.1, "or_greater") var pitch := 1.8
@export_range(0, 4, 0.1, "or_greater") var roll := 0.6
@export_range(0, 4, 0.1, "or_greater") var yaw := 0.6

# Standard friction. Zero is "asteroids" controls.
# This goes to 60 because it will be applied on a per delta basis.
@export_range(0, 60, 0.1) var friction_std: float = 0.99

# Amount to lerp the impulse and turning.
# 0.01 is incredibly sluggish and floaty
# Even 0.1 is quite responsive, but a bit gradual
# 1.0 is no lerp at all. aka immediate snap to target
# value. BUT 60 or more should actually be 1.0 because
# this value is multiplied by delta.
@export_range(0.1, 100, 0.1, "or_less") var impulse_lerp := 1.0 # Used to be 1 for player and 10 for NPCs
# turning_lerp is the lerp used for changing pitch,
# roll, and yaw.
@export_range(0.1, 100, 0.1, "or_less") var turning_lerp := 3.5
