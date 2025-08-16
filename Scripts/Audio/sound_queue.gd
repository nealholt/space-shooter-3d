class_name SoundQueue extends Node
## Inspiration came from this tutorial:
## Organize Sound In Godot 4 by Cadoink (Mar 6, 2023): https://www.youtube.com/watch?v=bdsHf08QmZ4

const SOUNDQUEUE_SCENE:PackedScene = preload("res://Scenes/audio/sound_queue.tscn")


var next:int = 0
var audio_players : Array
var sound_effect : SoundEffectSetting


static func new_sound_queue(my_parent:Node, sf:SoundEffectSetting) -> SoundQueue:
	var sq := SOUNDQUEUE_SCENE.instantiate()
	sq.sound_effect = sf
	my_parent.add_child(sq)
	return sq


func _ready() -> void:
	for i in sound_effect.limit:
		var new_audio: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(new_audio)
		new_audio.stream = sound_effect.sound_effect
		new_audio.volume_db = sound_effect.volume
		audio_players.push_back(new_audio)


# Play next audio and return index of the audio player
# for possibly later reference
func play(_loc:Vector3) -> int:
	var index := next
	# If the current audio is playing then we're maxed
	# out on this sound. Prefer to skip than to interrupt
	# and replay a currently playing sound
	if audio_players[next].playing:
		return -1
	# Set up and play the audio
	audio_players[next].pitch_scale = sound_effect.pitch_scale
	audio_players[next].pitch_scale += randf_range(-sound_effect.pitch_randomness, sound_effect.pitch_randomness )
	audio_players[next].play()
	# Increment next
	next = (next+1) % audio_players.size()
	return index


func stop_all() -> void:
	for a in audio_players:
		a.stop()

func stop(index:int=0) -> void:
	audio_players[index].stop()

func get_volume(index:int=0) -> float:
	return audio_players[index].volume_db

func set_volume(new_volume:float, index:int=0) -> void:
	audio_players[index].volume_db = new_volume

func set_volume_percent(percent:float, index:int=0) -> void:
	audio_players[index].volume_db = percent * (sound_effect.volume_max-sound_effect.volume_min) + sound_effect.volume_min

func print_summary() -> void:
	print("    Summary for ", SoundEffectSetting.SOUND_EFFECT_TYPE.keys()[sound_effect.type])
	var count:int = 0
	for player in audio_players:
		if player.playing:
			count+=1
	print('        %d playing' % count)
	print('        index: %d' % next)
