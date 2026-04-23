class_name ShieldGenerator extends Node3D
# Just pop this baby onto any object as a peer of a shield
# then destroying this will destroy the shield as well.

var shield:Shield

func _ready() -> void:
	# Get peer shield, if any.
	var p = get_parent()
	for c in p.get_children():
		if c is Shield:
			shield = c
	# If not, push an error
	if !shield:
		push_error('Shield Generator used without a Shield.')

func _on_health_component_died() -> void:
	# Destroy the shield unless it's already dead
	if is_instance_valid(shield):
		shield.permanently_destroy()
	# Destroy self
	Callable(queue_free).call_deferred()
