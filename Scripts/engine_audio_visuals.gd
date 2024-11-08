extends Node3D
class_name EngineAV

# This class manages the audio visual aspects of
# ship engines.
# For now there is just some audio.

# Current audio came from here originally:
# https://imgur.com/gallery/f-18-carrier-catapult-assisted-takeoff-JcPruZg
# I edited it in Audacity.

@export var afterburner_volume:float = -7 # dB
@export var afterburner_pitch:float = 1.5

@export var default_volume:float = -15 # dB
@export var default_pitch:float = 1.0

@export var drift_volume:float = -40 # dB
@export var drift_pitch:float = 0.0

@export var brake_volume:float = -10 # dB
@export var brake_pitch:float = 0.3

@onready var engine_audio := $AudioStreamPlayer3D
var tween:Tween

# Use state to control whether or not a shift happens
var state := EngineState.DEFAULT
enum EngineState {
	DEFAULT,
	AFTERBURNER,
	DRIFT,
	BRAKE
}


func _ready() -> void:
	engine_audio.play()


func shift2afterburners(time:float) -> void:
	# If already in the state, do nothing.
	if state == EngineState.AFTERBURNER:
		return
	if !engine_audio.playing:
		engine_audio.play()
	# Official documentation recommends this pattern
	# for cutting off the old tween and starting a
	# new one
	#https://docs.godotengine.org/en/stable/classes/class_tween.html
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(engine_audio, "volume_db", afterburner_volume, time)
	tween.tween_property(engine_audio, "pitch_scale", afterburner_pitch, time)
	await tween.finished
	state = EngineState.AFTERBURNER


func shift2default(time:float) -> void:
	# If already in the state, do nothing.
	if state == EngineState.DEFAULT:
		return
	if !engine_audio.playing:
		engine_audio.play()
	# Official documentation recommends this pattern
	# for cutting off the old tween and starting a
	# new one
	#https://docs.godotengine.org/en/stable/classes/class_tween.html
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(engine_audio, "volume_db", default_volume, time)
	tween.tween_property(engine_audio, "pitch_scale", default_pitch, time)
	await tween.finished
	state = EngineState.DEFAULT


func shift2drift(time:float) -> void:
	# If already in the state, do nothing.
	if state == EngineState.DRIFT:
		return
	# Official documentation recommends this pattern
	# for cutting off the old tween and starting a
	# new one
	#https://docs.godotengine.org/en/stable/classes/class_tween.html
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(engine_audio, "volume_db", drift_volume, time)
	tween.tween_property(engine_audio, "pitch_scale", drift_pitch, time)
	await tween.finished
	engine_audio.stop()
	state = EngineState.DRIFT


func shift2brake(_time:float) -> void:
	# If already in the state, do nothing.
	if state == EngineState.BRAKE:
		return
	if !engine_audio.playing:
		engine_audio.play()
	# This one doesn't tween, but snaps to
	if tween:
		tween.kill()
	engine_audio.volume_db = brake_volume
	engine_audio.pitch_scale = brake_pitch
	state = EngineState.BRAKE
