extends VisualEffect

@onready var smoke := $VFX_SmokeClouds
@onready var audio := $AudioStreamPlayer3D

var effects_live := 0
const TOTAL_EFFECTS := 2

func play() -> void:
	smoke.restart()
	audio.play()
	effects_live = TOTAL_EFFECTS

func is_playing() -> bool:
	return effects_live > 0

func stop() -> void:
	smoke.emitting = false
	audio.stop()
	effects_live = 0

func _on_part_finished() -> void:
	effects_live -= 1
	if effects_live < 1:
		_on_animation_finished()
