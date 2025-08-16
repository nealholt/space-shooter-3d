class_name SoundQueue3D extends SoundQueue
## Inspiration came from this tutorial:
## Organize Sound In Godot 4 by Cadoink (Mar 6, 2023): https://www.youtube.com/watch?v=bdsHf08QmZ4

const SOUNDQUEUE3D_SCENE:PackedScene = preload("res://Scenes/audio/sound_queue_3d.tscn")

# An array of remote transforms for longer-playing sounds
# that need to follow an object rather than play briefly
# at a position, for instance the machine gun sound or
# the reload noise.
var remote_ts : Array

static func new_sound_queue(my_parent:Node, sf:SoundEffectSetting) -> SoundQueue3D:
	var sq := SOUNDQUEUE3D_SCENE.instantiate()
	sq.sound_effect = sf
	my_parent.add_child(sq)
	return sq


func _ready() -> void:
	for i in sound_effect.limit:
		var new_audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		add_child(new_audio)
		new_audio.stream = sound_effect.sound_effect
		new_audio.volume_db = sound_effect.volume
		audio_players.push_back(new_audio)
		# Connect to finished signal in case there's a transform to clean up
		new_audio.finished.connect(_on_audio_finished.bind(i))
		# Add in a null for each audio so the remote transform
		# array is the same length.
		remote_ts.push_back(null)


# Play next audio and return index of the audio player
# for possibly later reference
func play(location:Vector3 = Vector3.ZERO) -> int:
	var index := next
	# If the current audio is playing then we're maxed
	# out on this sound. Prefer to skip than to interrupt
	# and replay a currently playing sound
	if audio_players[next].playing:
		return -1
	# Set up and play the audio
	audio_players[next].global_position = location
	audio_players[next].pitch_scale = sound_effect.pitch_scale
	audio_players[next].pitch_scale += randf_range(-sound_effect.pitch_randomness, sound_effect.pitch_randomness )
	audio_players[next].play()
	# Increment next
	next = (next+1) % audio_players.size()
	return index


func play_remote_transform(remote_mover:Node3D, location:Vector3 = Vector3.ZERO) -> int:
	# Play the effect
	var i := play(location)
	#print('Playing index %d remote' % i)
	# If nothing played, then abort
	if i == -1: return -1
	# Create a new remote transform, attach it
	# to the thing the sound should move with,
	# then set the transform's path to the sound
	remote_ts[i] = RemoteTransform3D.new()
	remote_mover.add_child(remote_ts[i])
	remote_ts[i].remote_path = audio_players[i].get_path()
	return i


# i is the index of the player that just finished
func _on_audio_finished(i:int) -> void:
	# If there is a corresponding remote transform, kill it
	if is_instance_valid(remote_ts[i]):
		remote_ts[i].queue_free()
		remote_ts[i] = null
