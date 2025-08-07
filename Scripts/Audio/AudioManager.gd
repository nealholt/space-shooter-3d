extends Node3D
## Audio manager node. Intended to be globally loaded as a 3D Scene.
## Handles [method create_3d_audio_at_location()] and
## [method create_audio()] to handle the playback and culling of
## simultaneous sound effects.
##
## To properly use, define [enum SoundEffect.SOUND_EFFECT_TYPE] for
## each unique sound effect, create a Node3D scene for this
## AudioManager script add those SoundEffect resources to this
## globally loaded script's [member sound_effects], and setup your
## individual SoundEffect resources. Then, use
## [method create_3d_audio_at_location()] and [method create_audio()]
## to play those sound effects either at a specific location or globally.
## 
## See https://github.com/Aarimous/AudioManager for more information.
##
## @tutorial: https://www.youtube.com/watch?v=Egf2jgET3nQ
## 
## This has since been greatly modified for efficiency and ease of use
## and now also to be in 3D by Neal Holtschulte based on these tutorials:
## Organize Sound In Godot 4 by Cadoink (Mar 6, 2023)
## @tutorial: https://www.youtube.com/watch?v=bdsHf08QmZ4
## and Building a Simple and Powerful Audio System in Godot by
## Night Quest Games (November 8, 2023)
## @tutorial: https://www.nightquestgames.com/building-a-simple-audio-system-in-godot/
## Audio nodes are no longer created and destroyed willy-nilly, but
## are maintained in queues and pools.

var sound_effect_dict: Dictionary[int,SoundQueue] = {} ## Loads all registered SoundEffects on ready as a reference.

@export var sound_effects: Array[SoundEffectSetting] ## Stores all possible SoundEffects that can be played.


# The following is a little hacky, but I
# consolidated all the non-positional and 3D
# sound queues into one dictionary. Since enums
# are stored as int under the hood, this works
# by assuming that the enum + 1 is always the
# 3-dimensional version.

func _ready() -> void:
	# Load the sound effect dictionaries
	for sound_effect: SoundEffectSetting in sound_effects:
		sound_effect_dict[sound_effect.type] = SoundQueue.new_sound_queue(self,sound_effect)
		sound_effect_dict[sound_effect.type+1] = SoundQueue3D.new_sound_queue(self,sound_effect)


func error_check(type:SoundEffectSetting.SOUND_EFFECT_TYPE) -> void:
	if !sound_effect_dict.has(type):
		push_error("Audio Manager failed to find setting for type ", type)

## Plays a sound effect if the limit has not been reached. Otherwise does nothing. Returns index of audio stream played.
func play(type:int, loc:Vector3=Vector3.INF) -> int:
	if loc != Vector3.INF:
		type = type + 1
	error_check(type)
	return sound_effect_dict[type].play(loc)

func stop_all(type:int, use_3d:=false) -> void:
	if use_3d:
		type = type + 1
	error_check(type)
	sound_effect_dict[type].stop_all()

func stop(type:int, index:int=0, use_3d:=false) -> void:
	if use_3d:
		type = type + 1
	error_check(type)
	sound_effect_dict[type].stop(index)

func get_volume(type:int, index:int=0, use_3d:=false) -> float:
	if use_3d:
		type = type + 1
	error_check(type)
	return sound_effect_dict[type].get_volume(index)

func set_volume(type:int, new_volume:float, index:int=0, use_3d:=false) -> void:
	if use_3d:
		type = type + 1
	error_check(type)
	sound_effect_dict[type].set_volume(new_volume, index)

func set_volume_percent(type:int, percent:float, index:int=0, use_3d:=false) -> void:
	if use_3d:
		type = type + 1
	error_check(type)
	sound_effect_dict[type].set_volume_percent(percent, index)

func stop_everything() -> void:
	for audio in sound_effect_dict.values():
		audio.stop_all()
