extends Projectile

# Missile that automatically seeks the
# centermost enemy target ahead of it.

# Constant roll looks pretty.
@export var roll_amount:float = 10.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Roll a little
	rotate_z(roll_amount*delta)


# Override parent in order to set target to be
# centermost enemy.
func set_data(dat:ShootData) -> void:
	super.set_data(dat)
	if shooter.is_in_group("red_team"):
		target = Global.get_center_most_from_group("blue team",self)
	else:
		target = Global.get_center_most_from_group("red team",self)
