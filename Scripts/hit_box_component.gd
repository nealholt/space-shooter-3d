extends Area3D
class_name HitBoxComponent
# Inspired by this:
# https://www.youtube.com/watch?v=74y6zWZfQKk&t=184s

@export var health_component:HealthComponent

func damage(amount:int):
	if health_component:
		health_component.health -= amount
