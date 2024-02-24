extends Node
class_name HealthComponent
# Inspired by this:
# https://www.youtube.com/watch?v=74y6zWZfQKk&t=184s

signal health_lost
signal died

@export var max_health := 10

#Getters and Setters can be set right after the variable!
#https://www.udemy.com/course/complete-godot-3d/learn/lecture/40514288#questions
var health: int:
	# This setter runs whenever current_health is changed,
	# including basic assignment like in _ready()
	set(health_in):
		# https://www.udemy.com/course/complete-godot-3d/learn/lecture/40736150#questions
		# If health is decreasing
		if health_in < health:
			health_lost.emit()
		# Change health
		health = health_in
		# If dead
		if health <= 0:
			died.emit()


# Called when the node enters the scene tree for the first time.
func _ready():
	health = max_health


func set_max_health(h:int) -> void:
	max_health = h
	health = h
