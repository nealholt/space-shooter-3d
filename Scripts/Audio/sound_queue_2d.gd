class_name SoundQueue3D extends SoundQueue
## Inspiration came from this tutorial:
## Organize Sound In Godot 4 by Cadoink (Mar 6, 2023): https://www.youtube.com/watch?v=bdsHf08QmZ4

const SOUNDQUEUE3D_SCENE:PackedScene = preload("res://Scenes/audio/sound_queue_3d.tscn")


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
