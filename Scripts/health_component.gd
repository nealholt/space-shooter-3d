extends Node
class_name HealthComponent
# Inspired by this:
# https://www.youtube.com/watch?v=74y6zWZfQKk&t=184s

signal health_lost
signal died

@export var max_health := 10.0

# Only signal died once. If for some reason,
# later on a component gets resurrected, then
# this bool should be reset as part of that
# resurrection.
var signalled_died:bool = false

#Getters and Setters can be set right after the variable!
#https://www.udemy.com/course/complete-godot-3d/learn/lecture/40514288#questions
var health: float:
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
		if health <= 0 and !signalled_died:
			died.emit()
			signalled_died = true


# Called when the node enters the scene tree for the first time.
func _ready():
	health = max_health


func set_max_health(h:float) -> void:
	max_health = h
	health = h


func get_percent_health() -> float:
	return health/max_health
