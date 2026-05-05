extends VisualEffect

@onready var fire := $Fire
@onready var flash := $Flash
@onready var sparks := $Sparks
@onready var audio := $AudioStreamPlayer3D

var effects_live := 0
const TOTAL_EFFECTS := 4

func play() -> void:
	fire.restart()
	flash.restart()
	sparks.restart()
	audio.play()
	effects_live = TOTAL_EFFECTS

func is_playing() -> bool:
	return effects_live > 0

func stop() -> void:
	fire.emitting = false
	flash.emitting = false
	sparks.emitting = false
	audio.stop()
	effects_live = 0

func _on_part_finished() -> void:
	effects_live -= 1
	if effects_live < 1:
		_on_animation_finished()
