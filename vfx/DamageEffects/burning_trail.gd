class_name BurningTrail extends Node3D

@onready var major_damage: Node3D = $MajorDamage
@onready var major_damage_line_sparks: Node3D = $MajorDamageLineSparks
@onready var mild_damage: Node3D = $MildDamage

# This class display a trail of smoke and
# flame behind damaged ships. Different percent
# damages results in different displays.
# _amount is the amount of damage
# ship.gd connects health_lost signal to this function
func display_damage(health:HealthComponent, _amount:float) -> void:
	var percent_health:float = health.get_percent_health()
	if percent_health <= 0.0: #This will happen for death animation
		mild_damage.stop_emitting()
		major_damage_line_sparks.stop_emitting()
		major_damage.start_emitting()
	elif percent_health < 0.5:
		mild_damage.stop_emitting()
		major_damage_line_sparks.start_emitting()
		major_damage.stop_emitting()
	elif percent_health < 0.8:
		mild_damage.start_emitting()
		major_damage_line_sparks.stop_emitting()
		major_damage.stop_emitting()
