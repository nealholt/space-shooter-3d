extends Node3D
class_name Shield

# NOTE: Under the FresnelAura mesh, under Resource,
# I set "Local to Scene" to "On"
# Otherwise, damaging one shield causes ALL
# shields to flicker.

@export var explosion:VisualEffectSetting.VISUAL_EFFECT_TYPE

@export var max_health := 10

@onready var shader_ref : ShaderMaterial = $FresnelAura.mesh.surface_get_material(0)
var fresnel_power_current := 2.0
var fresnel_power_default := 2.0
var fresnel_power_when_struck := 0.05
var fresnel_power_lerp_speed := 30.0

var fresnel_emission_current := 1.0
var fresnel_emission_default := 1.0
var fresnel_emission_when_struck := 100.0
var fresnel_emission_lerp_speed := 10.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HealthComponent.set_max_health(max_health)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Drift fresnel parameters back toward default after being struck
	fresnel_power_current = lerp(fresnel_power_current, fresnel_power_default, delta * fresnel_power_lerp_speed)
	fresnel_emission_current = lerp(fresnel_emission_current, fresnel_emission_default, delta * fresnel_emission_lerp_speed)
	# https://forum.godotengine.org/t/how-to-access-change-visualshader-uniform-variables-from-within-a-script/19668
	shader_ref.set("shader_parameter/FresnelPower", fresnel_power_current)
	shader_ref.set("shader_parameter/EmissionStrength", fresnel_emission_current)
	# There's also this
	# https://www.reddit.com/r/godot/comments/1f6q09q/when_one_energy_shield_gets_hit_every_shield/
	# But my solution was to go under the FresnelAura mesh,
	# under Resource, and set "Local to Scene" to "On"
	# Otherwise, changing the above parameters on one shield
	# changes it on ALL shields.


func _on_health_component_health_lost() -> void:
	# Dramatically alter shield opacity and emission when struck
	fresnel_power_current = fresnel_power_when_struck
	fresnel_emission_current = fresnel_emission_when_struck


func _on_health_component_died() -> void:
	# Disable further collisions and hide aura
	# Without set_deferred there's a "Function blocked
	# during in/out signal" error.
	set_deferred("$HitBoxComponent.monitoring", false)
	set_deferred("$HitBoxComponent.monitorable", false)
	$FresnelAura.visible = false
	# Start the fireworks!
	VfxManager.play(explosion, global_position)
	# Delete self at the end of the frame
	Callable(queue_free).call_deferred()
