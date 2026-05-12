class_name MissileCues extends Node

# Interval between subsequent audio cues
@export var warning_interval:int = 2000 ## millis

# Grouping nodes for two sets of audio cues
@onready var lock_audio: Node = $LockAudio
@onready var fired_audio: Node = $FiredAudio

# For picking audio to play
var rng = RandomNumberGenerator.new() # For positioning flyby camera

# Time in millis of most recent audiocues so we can prevent overlap
var lock_warning_time:int = 0
var fired_warning_time:int = 0

func _ready() -> void:
	setup_missile_cues.call_deferred()

# Register self with the global script
func setup_missile_cues() -> void:
	Global.missile_cues = self

func connect_to_player(p:Ship) -> void:
	p.missile_locked.connect(missile_lock_on_player)
	p.missile_fired_inbound.connect(missile_inbound)

# This is actually triggered when the enemy starts
# its countdown to missile lock
func missile_lock_on_player() -> void:
	# Space out audio cues by at least warning_interval milliseconds
	var current_time:int = Time.get_ticks_msec()
	if current_time-lock_warning_time < warning_interval:
		#print('lock cue suppressed')
		return
	# Play audio
	var i:int = rng.randi() % lock_audio.get_child_count()
	var audio:AudioStreamPlayer = lock_audio.get_child(i)
	audio.play()
	lock_warning_time = current_time

func missile_inbound() -> void:
	# Space out audio cues by at least warning_interval milliseconds
	var current_time:int = Time.get_ticks_msec()
	if current_time-fired_warning_time < warning_interval:
		#print('fired cue suppressed')
		return
	# Play audio
	var i:int = rng.randi() % fired_audio.get_child_count()
	var audio:AudioStreamPlayer = fired_audio.get_child(i)
	audio.play()
	fired_warning_time = current_time
