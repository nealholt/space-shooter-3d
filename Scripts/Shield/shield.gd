class_name Shield extends Node3D

const SHIELD_SCENE:PackedScene = preload("res://Scenes/Shield/shield.tscn")

# NOTE: Under the FresnelAura mesh, under Resource,
# Set "Local to Scene" to "On"
# Otherwise, damaging one shield causes ALL
# shields to flicker.

@export var explosion:VisualEffectSetting.VISUAL_EFFECT_TYPE
@export var max_health := 10
@export var recharge_delay := 15 ## seconds

@onready var hit_box_component: HitBoxComponent = $HitBoxComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var fresnel_aura: MeshInstance3D = $FresnelAura
@onready var timer: Timer = $Timer
@onready var shader_ref : ShaderMaterial = $FresnelAura.mesh.surface_get_material(0)
var fresnel_power_current := 2.0
var fresnel_power_default := 2.0
var fresnel_power_when_struck := 0.05
var fresnel_power_lerp_speed := 30.0

var fresnel_emission_current := 1.0
var fresnel_emission_default := 1.0
var fresnel_emission_when_struck := 100.0
var fresnel_emission_lerp_speed := 10.0


static func new_shield(my_parent:Node3D, scal:float) -> Shield:
	var s := SHIELD_SCENE.instantiate()
	# Order matters for these next three lines of code
	my_parent.add_child(s)
	s.scale = Vector3(scal,scal,scal)
	return s


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
	# Disable further collisions
	# Without set_deferred there's a "Function blocked
	# during in/out signal" error.
	# Also, the monitorable = false doesn't seem to do
	# anything. There are still collisions unless the
	# collision layer is set to false. I'm not sure why,
	# but for now I'll just turn off both.
	hit_box_component.set_deferred('monitorable', false)
	hit_box_component.call_deferred('set_collision_layer_value', 4, false)
	# Hide aura
	fresnel_aura.visible = false
	# Turn off processing
	set_physics_process(false)
	# Start the fireworks
	VfxManager.play(explosion, global_position)
	# Start a timer for shield to recharge
	timer.start(recharge_delay)


func _on_timer_timeout() -> void:
	# Reset the shield
	# Shrink shield way down and tween it back to full size
	# https://www.reddit.com/r/godot/comments/14gt180/all_possible_tweening_transition_types_and_easing/
	# Shrink-and-tween-back visuals:
	fresnel_aura.scale = Vector3(0.1, 0.1, 0.1)
	var tween:Tween = create_tween()
	tween.tween_property(fresnel_aura,
		'scale',
		Vector3(1.0, 1.0, 1.0), 1.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# Shrink-and-tween-back hitbox
	hit_box_component.scale = Vector3(0.1, 0.1, 0.1)
	tween = create_tween()
	tween.tween_property(hit_box_component,
		'scale',
		Vector3(1.0, 1.0, 1.0), 1.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# Re-enable collisions
	hit_box_component.set_deferred('monitorable', true)
	hit_box_component.call_deferred('set_collision_layer_value', 4, true)
	# Make aura visible
	fresnel_aura.visible = true
	# Turn on processing
	set_physics_process(true)
	# Reset health
	health_component.set_max_health(max_health)
	# This must be reset for the died signal to trigger again
	health_component.signalled_died = false


func permanently_destroy() -> void:
	# Start the fireworks
	VfxManager.play(explosion, global_position)
	# Self delete
	Callable(queue_free).call_deferred()
