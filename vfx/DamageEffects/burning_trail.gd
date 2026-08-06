class_name BurningTrail extends Node3D

# NOTE: Particles disappear and then sometimes annoyingly reappear
# when the camera moves away and then moves back to them. The issue
# can be addressed under Drawing -> Visibility AABB
# See also: https://docs.godotengine.org/en/stable/classes/class_aabb.html#class-aabb
# And: https://forum.godotengine.org/t/regarding-off-camera-particle-emision/27366

@onready var major_damage_line_sparks: Node3D = $MajorDamageLineSparks
@onready var major_damage: Node3D = $MajorDamage
@onready var mild_damage: Node3D = $MildDamage

# This class display a trail of smoke and
# flame behind damaged ships. Different percent
# damages results in different displays.
# _amount is the amount of damage
# ship.gd connects health_lost signal to this function
func display_damage(health:HealthComponent, _amount:float) -> void:
	var percent_health:float = health.get_percent_health()
	if percent_health <= 0.2: # This will happen for death animation too
		major_damage_line_sparks.start_emitting()
		major_damage.stop_emitting()
		mild_damage.stop_emitting()
	elif percent_health < 0.5:
		major_damage_line_sparks.stop_emitting()
		major_damage.start_emitting()
		mild_damage.stop_emitting()
	elif percent_health < 0.8:
		major_damage_line_sparks.stop_emitting()
		major_damage.stop_emitting()
		mild_damage.start_emitting()

# Turn on one_shot for the biggest damage effect.
# This should only happen when the ship this trail
# is attached to has taken fatal damage
func last_time() -> void:
	major_damage_line_sparks.last_time()
