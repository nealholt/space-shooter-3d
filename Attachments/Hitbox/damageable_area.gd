class_name DamageableArea extends Area3D

signal damaged(amount:float, damager)

# So damageables know what team they are on. These
# are set in team_setup.gd
var ally_team:String
var enemy_team:String


func damage(amount:float, damager=null):
	damaged.emit(amount, damager)
