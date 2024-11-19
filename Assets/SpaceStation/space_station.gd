extends Node3D


func _on_health_component_died() -> void:
	Callable(queue_free).call_deferred()
