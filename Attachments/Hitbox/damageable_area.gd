class_name DamageableArea extends Area3D

signal damaged(data:ShootData)

# So damageables know what team they are on. These
# are set in team_setup.gd
var ally_team:String
var enemy_team:String

# Anyone can damage this except for the damage_exception
# ship. Currently this is used to prevent ships from
# shooting down their own missiles.
var damage_exception:Ship


func damage(data:ShootData):
	damaged.emit(data)
