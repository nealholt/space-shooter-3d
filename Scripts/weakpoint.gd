extends Node3D

signal destroyed

@export var hitpoints:int = 10

func _ready() -> void:
	$HealthComponent.set_max_health(hitpoints)

func _on_health_component_died() -> void:
	destroyed.emit()
	VfxManager.play(VisualEffectSetting.VISUAL_EFFECT_TYPE.SHIELD_EXPLOSION, global_position)
	Callable(queue_free).call_deferred()
