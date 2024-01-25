extends Area3D
class_name HitBoxComponent
# Inspired by this:
# https://www.youtube.com/watch?v=74y6zWZfQKk&t=184s

@export var health_component:HealthComponent
@export var hit_feedback:HitFeedback

func damage(amount:int):
	if health_component:
		health_component.health -= amount
	if hit_feedback:
		hit_feedback.hit()
