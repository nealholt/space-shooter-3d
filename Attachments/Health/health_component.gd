extends Node
class_name HealthComponent
# Inspired by this:
# https://www.youtube.com/watch?v=74y6zWZfQKk&t=184s

signal health_lost(me:HealthComponent, amount:float)
signal died

@export var max_health := 10.0
@export var weakpoint_damage:float = 1.0 ## health lost per weakpoint destroyed
@export var weakpoint_group:Node3D

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
	set(new_health):
		# https://www.udemy.com/course/complete-godot-3d/learn/lecture/40736150#questions
		# If health is decreasing
		if new_health < health:
			health_lost.emit(self, health-new_health)
		# Change health
		health = new_health
		# If dead. Check against 0.5 in order to round down.
		if health <= 0.5 and !signalled_died:
			died.emit()
			signalled_died = true


# Called when the node enters the scene tree for the first time.
func _ready():
	health = max_health
	# Check for weakpoints
	if weakpoint_group:
		# Connect to weakpoint destroyed signal
		for wp in weakpoint_group.get_children():
			wp.connect('destroyed', _on_weakpoint_destroyed)


func set_max_health(h:float) -> void:
	max_health = h
	health = h


func get_percent_health() -> float:
	return health/max_health


func _on_weakpoint_destroyed() -> void:
	health -= weakpoint_damage


func is_dead() -> bool:
	return health <= 0
