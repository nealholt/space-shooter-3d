extends Node3D
class_name BurningTrail

# This class display a trail of smoke and
# flame behind damaged ships. Different percent
# damages results in different displays.
func display_damage(percent_health: float) -> void:
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
