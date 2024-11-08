extends Node3D
class_name EngineAV

# This class manages the audio visual aspects of
# ship engines.
# For now there is just some audio.

@export var afterburner_volume:float = -7 # dB
@export var afterburner_pitch:float = 1.5

@export var default_volume:float = -15 # dB
@export var default_pitch:float = 1.0

@export var drift_volume:float = -40 # dB
@export var drift_pitch:float = 0.0

@export var brake_volume:float = -10 # dB
@export var brake_pitch:float = 0.3

@onready var engine_audio := $AudioStreamPlayer3D
var tween:Tween = create_tween()

# TODO 
# Current state

func shift2afterburners(time:float) -> void:
	tween.stop()
	if !engine_audio.playing:
		engine_audio.play()
	tween.set_parallel(true)
	tween.tween_property(engine_audio, "volume_db", afterburner_volume, time)
	tween.tween_property(engine_audio, "pitch_scale", afterburner_pitch, time)

func shift2default(time:float) -> void:
	tween.stop()
	if !engine_audio.playing:
		engine_audio.play()
	tween.set_parallel(true)
	tween.tween_property(engine_audio, "volume_db", default_volume, time)
	tween.tween_property(engine_audio, "pitch_scale", default_pitch, time)

func shift2drift(time:float) -> void:
	tween.stop()
	tween.set_parallel(true)
	tween.tween_property(engine_audio, "volume_db", drift_volume, time)
	tween.tween_property(engine_audio, "pitch_scale", drift_pitch, time)
	await tween.finished
	engine_audio.stop()

func shift2brake(time:float) -> void:
	# This one doesn't tween, but snaps to
	if !engine_audio.playing:
		engine_audio.play()
	tween.stop()
	engine_audio.volume_db = brake_volume
	engine_audio.pitch_scale = brake_pitch
