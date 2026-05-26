class_name ShieldGenerator extends Node3D
# Just pop this baby onto any object as a peer of a shield
# then destroying this will destroy the shield as well.

@export var shield:Shield

func _ready() -> void:
	if !shield:
		push_error('Shield Generator used without a Shield. Did you forget to attach the components for '+get_parent().name)

func _on_health_component_died() -> void:
	# Destroy the shield unless it's already dead
	if is_instance_valid(shield):
		shield.permanently_destroy()
	# Destroy self
	Callable(queue_free).call_deferred()
