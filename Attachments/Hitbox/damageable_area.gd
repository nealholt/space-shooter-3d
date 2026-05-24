class_name DamageableArea extends Area3D

signal damaged(amount:float, damager)

func damage(amount:float, damager=null):
	damaged.emit(amount, damager)
