class_name MissileCues extends Node

# Static self reference.
# Now any script can reference the MissileCues like so:
# MissileCues.mc
# BE WARNED: This will not work correctly if there is more
# than one MissileCues in a scene.
static var mc:MissileCues = null

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
	# Make this scene statically accessible
	mc = self

func connect_to_player(p:Ship) -> void:
	var hitbox:HitBoxComponent = p.get_hitbox()
	hitbox.missile_locked.connect(missile_lock_on_player)
	hitbox.missile_fired_inbound.connect(missile_inbound)

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
