extends VisualEffect

var still_playing := false

func play() -> void:
	$".".restart()
	still_playing = true

func is_playing() -> bool:
	return still_playing

func _on_animation_finished() -> void:
	super()
	$".".emitting = false
	still_playing = false

func _on_finished() -> void:
	_on_animation_finished()
