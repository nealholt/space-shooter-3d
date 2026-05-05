extends Node3D
## Audio manager node. Intended to be globally loaded as a 3D Scene.
## Handles [method create_3d_audio_at_location()] and
## [method create_audio()] to handle the playback and culling of
## simultaneous sound effects.
##
## To properly use, define [enum SoundEffect.SOUND_EFFECT_TYPE] for
## each unique sound effect, create a Node3D scene for this
## AudioManager script, add those SoundEffect resources to this
## globally loaded script's [member sound_effects], and setup your
## individual SoundEffect resources.
## 
## See https://github.com/Aarimous/AudioManager for more information.
##
## @tutorial: https://www.youtube.com/watch?v=Egf2jgET3nQ
## 
## This has since been greatly modified by Neal Holtschulte
## based on these tutorials:
## Organize Sound In Godot 4 by Cadoink (Mar 6, 2023)
## @tutorial: https://www.youtube.com/watch?v=bdsHf08QmZ4
## and Building a Simple and Powerful Audio System in Godot by
## Night Quest Games (November 8, 2023)
## @tutorial: https://www.nightquestgames.com/building-a-simple-audio-system-in-godot/
## Audio nodes are no longer created and destroyed willy-nilly, but
## are maintained in queues and pools.

var sound_effect_dict: Dictionary[int,SoundQueue] = {} ## Loads all registered SoundEffects on ready as a reference.
var sound_effect_dict_3d: Dictionary[int,SoundQueue] = {} ## Loads all registered SoundEffects on ready as a reference.

@export var sound_effects: Array[SoundEffectSetting] ## Stores all possible SoundEffects that can be played.


func _ready() -> void:
	# Load the sound effect dictionaries
	for sound_effect: SoundEffectSetting in sound_effects:
		sound_effect_dict[sound_effect.type] = SoundQueue.new_sound_queue(self,sound_effect)
		sound_effect_dict_3d[sound_effect.type] = SoundQueue3D.new_sound_queue(self,sound_effect)


## Plays a sound effect if the limit has not been reached. Otherwise does nothing. Returns index of audio stream played.
func play(type:int, loc:Vector3=Vector3.INF) -> int:
	#print("Playing ", SoundEffectSetting.SOUND_EFFECT_TYPE.keys()[type])
	if loc != Vector3.INF:
		return sound_effect_dict_3d[type].play(loc)
	else:
		return sound_effect_dict[type].play(loc)

## Plays a sound effect if the limit has not been reached. Otherwise does nothing. Returns index of audio stream played.
func play_remote_transform(type:int, remote_mover:Node3D, loc:Vector3=Vector3.ZERO) -> int:
	#print("Playing remote ", SoundEffectSetting.SOUND_EFFECT_TYPE.keys()[type])
	return sound_effect_dict_3d[type].play_remote_transform(remote_mover, loc)

func stop_all(type:int, use_3d:=false) -> void:
	if use_3d:
		sound_effect_dict_3d[type].stop_all()
	else:
		sound_effect_dict[type].stop_all()

func stop(type:int, index:int=0, use_3d:=false) -> void:
	if use_3d:
		sound_effect_dict_3d[type].stop(index)
	else:
		sound_effect_dict[type].stop(index)

func get_volume(type:int, index:int=0, use_3d:=false) -> float:
	if use_3d:
		return sound_effect_dict_3d[type].get_volume(index)
	else:
		return sound_effect_dict[type].get_volume(index)

func set_volume(type:int, new_volume:float, index:int=0, use_3d:=false) -> void:
	if use_3d:
		sound_effect_dict_3d[type].set_volume(new_volume, index)
	else:
		sound_effect_dict[type].set_volume(new_volume, index)

func set_volume_percent(type:int, percent:float, index:int=0, use_3d:=false) -> void:
	if use_3d:
		sound_effect_dict_3d[type].set_volume_percent(percent, index)
	else:
		sound_effect_dict[type].set_volume_percent(percent, index)

func stop_everything() -> void:
	for audio in sound_effect_dict.values():
		audio.stop_all()
	for audio in sound_effect_dict_3d.values():
		audio.stop_all()

func print_summary() -> void:
	print('\nSummary for non-positional audio:')
	for audio in sound_effect_dict.values():
		audio.print_summary()
	print('Summary for 3d-positional audio:')
	for audio in sound_effect_dict_3d.values():
		audio.print_summary()
