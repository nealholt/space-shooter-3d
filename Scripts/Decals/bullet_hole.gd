extends Node3D

# Source:
# https://www.youtube.com/watch?v=8vFOOglWW3w

func _on_timer_timeout() -> void:
	queue_free()
