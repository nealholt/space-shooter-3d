extends ProjectileRay

# Missile that automatically seeks the
# centermost enemy target ahead of it.

# Constant roll looks pretty.
@export var roll_amount:float = 10.0
# I thought that a little pitch might
# cause a corkscrew pattern, but it doesn't
# seem to work.
#@export var pitch_amount:float = 10.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Roll a little
	rotate_z(roll_amount*delta)
	# Tried some pitch, but it didn't add anything.
	#rotate_y(pitch_amount*delta)


# Override parent in order to set target to be
# centermost enemy.
func set_data(dat:ShootData) -> void:
	super.set_data(dat)
	if dat.shooter.is_in_group("red_team"):
		dat.target = Global.get_center_most_from_group("blue team",self)
	else:
		dat.target = Global.get_center_most_from_group("red team",self)
