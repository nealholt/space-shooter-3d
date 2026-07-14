class_name BurningTrail extends Node3D

# This class display a trail of smoke and
# flame behind damaged ships. Different percent
# damages results in different displays.
# _amount is the amount of damage
# ship.gd connects health_lost signal to this function
func display_damage(health:HealthComponent, _amount:float) -> void:
	var percent_health:float = health.get_percent_health()
	if percent_health <= 0.0: #This will happen for death animation
		$MildDamage.stop_emitting()
		$MajorDamageLineSparks.stop_emitting()
		$MajorDamage.start_emitting()
	elif percent_health < 0.3:
		$MildDamage.stop_emitting()
		$MajorDamageLineSparks.start_emitting()
		$MajorDamage.stop_emitting()
	elif percent_health < 0.6:
		$MildDamage.start_emitting()
		$MajorDamageLineSparks.stop_emitting()
		$MajorDamage.stop_emitting()
