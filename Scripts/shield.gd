extends Node3D

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

# Sound to be played on death. Self-freeing.
@export var pop_player: PackedScene

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


func _on_health_component_health_lost() -> void:
	# Dramatically alter shield opacity and emission when struck
	fresnel_power_current = fresnel_power_when_struck
	fresnel_emission_current = fresnel_emission_when_struck


func _on_health_component_died() -> void:
	# Create self-freeing audio to play pop sound
	var on_death_sound = pop_player.instantiate()
	get_tree().get_root().add_child(on_death_sound)
	on_death_sound.play_then_delete(global_position)
	# Wait until the end of the frame to execute queue_free
	Callable(queue_free).call_deferred()
